/*
  Author : Rahul Malhotra
  Description : Template for Custom plugin for OAuth Authentication Salesforce
  Website:- https://sfdcstop.blogspot.com
  YouTube:- https://www.youtube.com/c/sfdcstop
  Find me on:- @rahulcoder (Twitter), @imrahulmalhotra (Instagram), https://www.facebook.com/sfdcstop
*/
global class CustomAuthProviderTemplate extends Auth.AuthProviderPluginClass {

/* 
  Create a custom metadata consisting of the following fields,
  add any new field if required by the third party api you're connecting too.
*/

  private String clientId;
  private String clientSecret;
  private String accessTokenUrl;
  private String authorizationUrl;
  private String scope;
  private String userInfoUrl;
  private String redirectUri;

  // This method is responsible for returning the custom metadata storing the api credentials and other details.
  global String getCustomMetadataType() {
    return 'Replace this text by your custom metadata api name';
  }

  // This method is responsible to initiate the authorization code flow
  global PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {
    /*
      Get all the fields required to form the authorization code url and return a pagereference to that url.
      I am using the api names of fields in my custom setting below. This is the same setting which was
      returned from the previous method.
    */
    clientId = authProviderConfiguration.get('Client_Id__c');
    authorizationUrl = authProviderConfiguration.get('Authorization_URL__c');
    scope = authProviderConfiguration.get('Scope__c');
    redirectUri = authProviderConfiguration.get('Redirect_URI__c');
    String url = authorizationUrl + '?scope='+scope+'&client_id='+clientId+'&redirect_uri='+redirectUri+'&state='+stateToPropagate;
    return new PageReference(url);
  }

  /*   
    This method is responsible to handle the callback from authorization code flow.
    Set the access token, refresh token and other parameters.
  */
  global Auth.AuthProviderTokenResponse handleCallback(Map<String, String> authProviderConfiguration, Auth.AuthProviderCallbackState state) {

    clientId = authProviderConfiguration.get('Client_Id__c');
    clientSecret = authProviderConfiguration.get('Client_Secret__c');
    scope = authProviderConfiguration.get('Scope__c');
    redirectUri = authProviderConfiguration.get('Redirect_URI__c');
    accessTokenUrl = authProviderConfiguration.get('Access_Token_URL__c');

    /*
     Code is required, state is optional 
     i.e. you'll get it if you passed it in the auth. code url in the above method.
   */
    Map<String,String> queryParams = state.queryParameters;
    String code = queryParams.get('code');
    String sfdcState = queryParams.get('state');

    /*
      Make a new HTTP Request to the access token URL.
      Make sure to pass the code received above in the request.
    */
    HttpRequest req = new HttpRequest();
    req.setEndpoint(accessTokenURL);
    req.setHeader('Accept','application/json');
    req.setMethod('POST');
    req.setBody('client_id='+clientId+'&client_secret='+clientSecret+'&code='+code+'&redirect_uri='+redirectUri+'&state='+sfdcState);

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();

    // Deserialize the response according to the response JSON using the wrapper made at the end of file.
    AccessTokenResponseWrapper response = (AccessTokenResponseWrapper) JSON.deserialize(responseBody, AccessTokenResponseWrapper.class);

    // Pass auth. provider name, access token, refresh token and state in the below method respectively.
    return new Auth.AuthProviderTokenResponse('GithubAuth', response.access_token, null, sfdcState);
  }

  /* 
    This method is responsible to get the user information used for authentication from the external api.
    You can find a URL from the third party api that you can hit to get the current authenticated user info.
    If there is no such URL, you can also hard code values,
    you can also store the values in custom metadata and use that.
  */
  global Auth.UserData getUserInfo(Map<String, String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {

    /*
      Getting the user info url from the custom metadata.
      Getting the access token from the response we got from access token url.
    */
    userInfoUrl = authProviderConfiguration.get('User_Info_URL__c');
    String token = response.oauthToken;

    /*
      Making a new HTTP request to get the user information,
      in this case we need to manually set the access token in header.
      Format is:-
      Key:- Authorization
      Value:- <Token-Type><space><access-token> 
      Example Value:- Bearer 123123123
    */
    HttpRequest req = new HttpRequest();
    req.setHeader('Authorization', 'Bearer ' + token);
    req.setEndpoint(userInfoUrl);

    // Set the method type according to third party api, you can also make a post request here.
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);
    String responseBody = res.getBody();

    // Make a wrapper according to the response of User Info URL.
    UserInfoResponse infoApiResponse = (UserInfoResponse) JSON.deserialize(responseBody, UserInfoResponse.class);

    String userId, fullName, firstName, lastName, locale, loginURL;

    // Hardcoding the locale, you can also store it in custom metadata.
    locale = 'en-au';

    /* 
      Getting the login URL from custom metadata,
      it is usually the login URL of your 3rd party API portal.
    */
    loginURL = authProviderConfiguration.get('Login_URL__c');

    userId = infoApiResponse.login;
    fullName = infoApiResponse.fullName;
    firstName = infoApiResponse.firstName;
    lastName = infoApiResponse.lastName;

    /*
      Format or below returned userdata instance:- 
        UserData (
          identifier, => user id
          firstName, => first name of authenticated user
          lastName, => last name of authenticated user
          fullName, => full name of authenticated user
          email, => email of authenticated user
          link, => link of authenticated user profile (Ex:- https://www.facebook.com/sfdcstop)
          userName, => username of authenticated user
          locale, => standard locale of authenticated user
          provider, => name of your 3rd party provider
          siteLoginUrl, => 3rd party login page url
          attributeMap => any other data from 3rd party that you can store as map of <string, string>
        )
      You can also pass null or hardcode value if something is not available as shown below.
    */
    return new Auth.UserData(
      userId,
      firstName,
      lastName,
      fullName,
      null,
      null, 
      userId,
      locale,
      'Replace me with your 3rd party provider name',
      loginURL,
      null
    );
  }

  /*
   Wrapper class to handle User Info API response.
   Create a wrapper class according to the response you're getting,
   like below sample will work if your response is as follows:-

   {
     "login":"123123123", 
     "fullName":"Rahul Malhotra",
     "firstName":"Rahul",
     "lastName":"Malhotra"
   }

 */
  public class UserInfoResponse {
    public String login;
    public String fullName;
    public String firstName;
    public String lastName;
  }

  /*
   Wrapper class to handle Access Token API response.
   Create a wrapper class according to the response you're getting,
   like below sample will work if your response is as follows:-

   {
     "access_token":"123123123", 
     "scope":"scope1,scope2", 
     "token_type":"bearer"
   }

 */
  public class AccessTokenResponseWrapper {
    public String access_token;
    public String token_type;
    public String scope;
  }

}
