<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Github_Auth</label>
    <protected>false</protected>
    <values>
        <field>Access_Token_URL__c</field>
        <value xsi:type="xsd:string">https://github.com/login/oauth/access_token</value>
    </values>
    <values>
        <field>Authorization_URL__c</field>
        <value xsi:type="xsd:string">https://github.com/login/oauth/authorize</value>
    </values>
    <values>
        <field>Client_Id__c</field>
        <value xsi:type="xsd:string"><!-- GitHub Client Id --></value>
    </values>
    <values>
        <field>Client_Secret__c</field>
        <value xsi:type="xsd:string"><!-- GitHub Client Secret --></value>
    </values>
    <values>
        <field>Redirect_URI__c</field>
        <value xsi:type="xsd:string">https://login.salesforce.com/services/authcallback/<!-- Unique Id -->/Github_Auth</value>
    </values>
    <values>
        <field>Scope__c</field>
        <value xsi:type="xsd:string">gist</value>
    </values>
    <values>
        <field>User_Info_URL__c</field>
        <value xsi:type="xsd:string">https://api.github.com/user</value>
    </values>
</CustomMetadata>
