public class ReceivedApplicationHandler {

    public static void handleFinalVerification(List<Received_Application__c> newList, Map<Id, Received_Application__c> oldMap) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Received_Application__c newRec : newList) {
            Received_Application__c oldRec = oldMap.get(newRec.Id);

            if (oldRec.Final_Verification__c != newRec.Final_Verification__c) {
                // Final_Verified__c has been changed by Agent
                if (newRec.Final_Verification__c != null) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { newRec.Email__c });
                    email.setSubject('Your Credit Card Application Status');

                    String body;

                    if (newRec.Final_Verification__c == 'Yes') {
                        body = 'Dear ' + newRec.Applicant_s_Name__c + ',\n\n' +
                               'Congratulations! 🎉\n\n' +
                               'We are thrilled to inform you that your application for a credit card has been thoroughly reviewed and successfully approved by our verification department.\n\n' +
                               '✅ Based on the information you provided and our internal eligibility checks, your application met all the criteria for approval.\n\n' +
                               'What happens next?\n' +
                               '- Our customer service team will reach out to you shortly for any final confirmations.\n' +
                               '- Your credit card will then be dispatched to your registered address within 5–7 working days.\n\n' +
                               'Please make sure your contact and delivery details are up to date.\n\n' +
                               'We truly appreciate the trust you have placed in us and look forward to serving you with the best of our financial products.\n\n' +
                               'Warm regards,\n' +
                               'Credit Card Approval Team\n' +
                               '---\n' +
                               'This is an automated message. For queries, contact our helpline.';
                    } else if (newRec.Final_Verification__c == 'No') {
                        body = 'Dear ' + newRec.Applicant_s_Name__c + ',\n\n' +
                               'Thank you for your recent application for a credit card with us.\n\n' +
                               'After careful review, we regret to inform you that your application could not be approved at this time.\n\n' +
                               '❌ While we understand this may be disappointing, we want to assure you that every application is evaluated fairly and thoroughly.\n\n';
                            body += 'Reason for Rejection: ' + newRec.Reason_For_Rejection__c + '\n\n';
                        

                        body += 'We encourage you to review your submitted information, and you may consider reapplying in the future if your circumstances change.\n\n' +
                                'If you would like to speak with someone regarding your application or need further clarification, feel free to contact our support team.\n\n' +
                                'Thank you for considering us as your credit partner.\n\n' +
                                'Sincerely,\n' +
                                'Credit Card Review Team\n' +
                                '---\n' +
                                'This is an automated message. For queries, contact our helpline.';
                    } else {
                        continue; // Skip unknown Final_Verified__c values
                    }

                    email.setPlainTextBody(body);
                    emailsToSend.add(email);
                }
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
}