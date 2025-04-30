trigger ReceivedApplicationNotifierTrigger on Received_Application__c (after insert) {
System.debug('Trigger fired on insert');
for(Received_Application__c app : Trigger.new) {
    System.debug('Sending Slack message for: '+ app.Name);
    SlackNotifierReceivedApplication.sendSlackMessage(app.Id, app.Name);
}
}