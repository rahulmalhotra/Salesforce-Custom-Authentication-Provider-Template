/*
  Author : Rahul Malhotra
  Description : Custom plugin for OAuth Authentication with Github
  Website:- https://sfdcstop.blogspot.com
  YouTube:- https://www.youtube.com/c/sfdcstop
  Find me on:- @rahulcoder (Twitter), @imrahulmalhotra (Instagram), https://www.facebook.com/sfdcstop
*/
global class GithubAuth extends Auth.AuthProviderPluginClass {

    private String clientId;
    private String clientSecret;
    private String accessTokenUrl;
    private String authorizationUrl;
    private String scope;
    private String userInfoUrl;
    private String redirectUri;

    // This method is responsible for returning the custom metadata storing the api credentials and other details
    global String getCustomMetadataType() {
        return 'GithubCredential__mdt';
    }

    // This method is responsible to initiate the authorization code flow
    global PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {
        clientId = authProviderConfiguration.get('Client_Id__c');
        authorizationUrl = authProviderConfiguration.get('Authorization_URL__c');
        scope = authProviderConfiguration.get('Scope__c');
        redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        String url = authorizationUrl + '?scope='+scope+'&client_id='+clientId+'&redirect_uri='+redirectUri+'&state='+stateToPropagate;
        return new PageReference(url);
    }

    /*   
      This method is responsible to handle the callback from authorization code flow
      set the access token, refresh token and other parameters
    */
    global Auth.AuthProviderTokenResponse handleCallback(Map<String, String> authProviderConfiguration, Auth.AuthProviderCallbackState state) {

       clientId = authProviderConfiguration.get('Client_Id__c');
       clientSecret = authProviderConfiguration.get('Client_Secret__c');
       scope = authProviderConfiguration.get('Scope__c');
       redirectUri = authProviderConfiguration.get('Redirect_URI__c');
       accessTokenUrl = authProviderConfiguration.get('Access_Token_URL__c');
       
       Map<String,String> queryParams = state.queryParameters;
       String code = queryParams.get('code');
       String sfdcState = queryParams.get('state');
       
       HttpRequest req = new HttpRequest();
       req.setEndpoint(accessTokenURL);
       req.setHeader('Accept','application/json');
       req.setMethod('POST');
       req.setBody('client_id='+clientId+'&client_secret='+clientSecret+'&code='+code+'&redirect_uri='+redirectUri+'&state='+sfdcState);

       Http http = new Http();
       HTTPResponse res = http.send(req);
       String responseBody = res.getBody();

       GithubResponse response = (GithubResponse) JSON.deserialize(responseBody, GithubResponse.class);
       
       return new Auth.AuthProviderTokenResponse('GithubAuth', response.access_token, null, sfdcState);
    }

    // This method is responsible to get the user information used for authentication from the external api
    global Auth.UserData getUserInfo(Map<String, String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {

      userInfoUrl = authProviderConfiguration.get('User_Info_URL__c');
      String token = response.oauthToken;

      HttpRequest req = new HttpRequest();
  		req.setHeader('Authorization', 'Bearer ' + token);
      req.setEndpoint(userInfoUrl);
      req.setMethod('GET');

      Http http = new Http();
      HTTPResponse res = http.send(req);
      String responseBody = res.getBody();

      GithubUserInfoResponse infoApiResponse = (GithubUserInfoResponse) JSON.deserialize(responseBody, GithubUserInfoResponse.class);

      String[] names = infoApiResponse.name.split(' ');
      
      String userId, fullName, firstName, lastName, locale, loginURL;

      locale = 'en-au';
      loginURL = authProviderConfiguration.get('Login_URL__c');

      userId = infoApiResponse.login;
      fullName = infoApiResponse.name;
      if(names.size()>=2) {
  			firstName = names[0];
  			lastName = names[1];
      }

      return new Auth.UserData(
        userId,
        firstName,
        lastName,
        fullName,
        null,
        null, 
        userId,
        locale,
        'Github',
        loginURL,
        null
      );
    }

    // Wrapper class to handle User Info API response
    public class GithubUserInfoResponse {
      public String login;
      public String name;
    }

    // Wrapper class to handle Access Token API response
    public class GithubResponse {
      public String access_token;
      public String token_type;
      public String scope;
    }

}
