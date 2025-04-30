trigger ReceivedApplicationTrigger on Received_Application__c (after update) {
        if (Trigger.isUpdate) {
            // Final Verification handling
            ReceivedApplicationHandler.handleFinalVerification(Trigger.new, Trigger.oldMap);
        }
    }