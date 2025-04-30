@RestResource(urlMapping='/application-status/*')
global class SlackApplicationStatusAPI {
 
    @HttpPost
    global static void handleApplicationStatus() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String responseText;
        // Extract the last part of the URL after '/application-status/'
        String path = req.requestURI;
        String statusFilter = '';
        if (path != null && path.contains('/application-status/')) {
            statusFilter = path.split('/application-status/')[1];
        }
        System.debug('🌟 Extracted statusFilter: ' + statusFilter);
 
        try {
            List<Received_Application__c> applications;
            String userFriendlyStatus = '';
 
            // Define the queries for different statuses
            if (statusFilter == 'approved') {
                applications = [
                    SELECT Name, Applicant_s_Name__c, Credit_Score__c, 
                           Applicant_s_Income__c, Email__c, Phone__c, Final_Verification__c
                    FROM Received_Application__c 
                    WHERE Status__c = 'Approved'
                ];
                userFriendlyStatus = '✅ Approved Applications';
            }
            else if (statusFilter == 'notapproved') {
                applications = [
                    SELECT Name, Applicant_s_Name__c, Credit_Score__c, 
                           Applicant_s_Income__c, Email__c, Phone__c, Final_Verification__c
                    FROM Received_Application__c 
                    WHERE Status__c = 'Not Approved'
                ];
                userFriendlyStatus = '❌ Not Approved Applications';
            }
            else if (statusFilter == 'manualreview') {
                applications = [
                    SELECT Name, Applicant_s_Name__c, Credit_Score__c, 
                           Applicant_s_Income__c, Email__c, Phone__c, Final_Verification__c
                    FROM Received_Application__c 
                    WHERE Status__c = 'Manual Review'
                ];
                userFriendlyStatus = '🛠️ Manual Review Applications';
            }
            else {
                responseText = '⚠️ Invalid request. Please specify a valid application status (approved, notapproved, manualreview).';
                sendResponse(responseText);
                return;
            }
 
            System.debug('⚡ Query result count: ' + applications.size());
 
            if (applications.isEmpty()) {
                responseText = '🚫 No ' + userFriendlyStatus + ' found.';
            } else {
                responseText = '📋 *' + userFriendlyStatus + '*:\n\n';
                for (Received_Application__c app : applications) {
                    responseText += '🔹 *Application ID:* ' + app.Name + '\n';
                    responseText += '👤 *Applicant Name:* ' + app.Applicant_s_Name__c + '\n';
                    responseText += '📈 *Credit Score:* ' + String.valueOf(app.Credit_Score__c) + '\n';
                    responseText += '💵 *Applicant Income:* ₹' + String.valueOf(app.Applicant_s_Income__c) + '\n';
                    responseText += '✉️ *Email:* ' + app.Email__c + '\n';
                    responseText += '📞 *Phone:* ' + app.Phone__c + '\n';
                    responseText += '🔍 *Final Verification:* ' + String.valueOf(app.Final_Verification__c) + '\n';
                    responseText += '----------------------------------\n';
                }
            }
        } catch (Exception e) {
            System.debug('❌ Error during query execution: ' + e.getMessage());
            responseText = '⚠️ An error occurred while fetching applications. Please try again later.';
        }
 
        sendResponse(responseText);
    }
 
    private static void sendResponse(String responseText) {
        RestResponse res = RestContext.response;
        Map<String, Object> jsonResponse = new Map<String, Object> {
            'response_type' => 'ephemeral',  // Show to the user who invoked it
            'text' => responseText
        };
        res.responseBody = Blob.valueOf(JSON.serialize(jsonResponse));
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json');
    }
}