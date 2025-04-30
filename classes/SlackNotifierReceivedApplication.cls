/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public with sharing class SlackNotifierReceivedApplication {
    private static final String NAMED_CREDENTIAL = 'callout:SlackWebHook';
 
    @future(callout=true)
    public static void sendSlackMessage(String recordId, String applicationName) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
 
        // New link format for Salesforce
        String recordLink = 'https://orgfarm-66e1786b62.lightning.force.com/lightning/r/Received_Application__c/'+recordId+'/view';
        // Flashy message with application name and record link
        String formattedMessage = '*:tada: New Application Received :tada:*\n' +
                                  '*Application Name:* ' + applicationName + '\n\n' +
                                  '*Record Link:* <' + recordLink + '|Click here to view the record>\n\n' +
                                  '_Please review the new application and take necessary actions._\n' +
                                  '*Thank you!*';
 
        Map<String, String> bodyMap = new Map<String, String>{
            'text' => formattedMessage
        };
        req.setBody(JSON.serialize(bodyMap));
 
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response Status: ' + res.getStatus());
            System.debug('Response StatusCode: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
 
            if (res.getStatusCode() != 200) {
                System.debug('Slack notification failed.');
            } else {
                System.debug('Slack notification sent successfully.');
            }
        } catch (Exception e) {
            System.debug('Slack notification exception: ' + e.getMessage());
        }
    }
}