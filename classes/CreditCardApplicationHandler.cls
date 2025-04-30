public with sharing class CreditCardApplicationHandler {
    
    @InvocableMethod(label='CreateCreditCardApplication')
    public static List<Response> createApplication(List<Request> requests) {
        List<Response> results = new List<Response>();
        List<User_Credit_Card_Application__c> appsToInsert = new List<User_Credit_Card_Application__c>();
        Map<String, Request> panToRequestMap = new Map<String, Request>();

        for (Request req : requests) {
            System.debug('Request: ' + JSON.serialize(req));
            Response res = new Response();

            if (req.dob == null) {
                res.status = 'Failed';
                res.message = 'Date of Birth is required.';
                results.add(res);
                continue;
            }

            if (req.employmentStatus != null &&
                req.employmentStatus.toLowerCase() == 'unemployed' &&
                req.annualIncome < 600000) {
                res.status = 'Failed';
                res.message = 'Income criteria not met for unemployed applicants.';
                results.add(res);
                continue;
            }

            List<User_Credit_Card_Application__c> existingApps = [
                SELECT Id FROM User_Credit_Card_Application__c 
                WHERE Pan_Number__c = :req.panNumber 
                LIMIT 1
            ];
            if (!existingApps.isEmpty()) {
                res.status = 'Failed';
                res.message = 'An application with this PAN Number already exists.';
                sendEmail(req.email, req.fullName, 'Application Rejected - Duplicate PAN',
                    'Our records show that an application with the same PAN number already exists in our system. ' +
                    'If you believe this is a mistake or wish to inquire further, please contact our support team. ' +
                    'For security reasons, we allow only one active application per PAN.');
                results.add(res);
                continue;
            }

            User_Credit_Card_Application__c app = new User_Credit_Card_Application__c(
                Name = req.fullName,
                Pan_Number__c = req.panNumber,
                Annual_Income__c = req.annualIncome,
                Email__c = req.email,
                Phone__c = req.phone,
                Residential_Address__c = req.address,
                DOB__c = req.dob,
                Employment_Status__c = req.employmentStatus
            );
            appsToInsert.add(app);
            panToRequestMap.put(req.panNumber, req);
        }

        if (!appsToInsert.isEmpty()) {
            insert appsToInsert;

            for (User_Credit_Card_Application__c app : appsToInsert) {
                Request req = panToRequestMap.get(app.Pan_Number__c);
                if (req != null) {
                    Response res = new Response();
                    res.status = 'Processing';
                    res.message = 'Application submitted. PAN verification pending.';
                    res.recordId = app.Id;
                    results.add(res);

                    verifyPANAsync(req.fullName, req.panNumber, req.email, req.fullName, app.Id);
                }
            }
        }

        return results;
    }

    @future(callout=true)
    public static void verifyPANAsync(String fullName, String panNumber, String email, String applicantName, Id appId) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Credit_Api/api/credits/credit-score');


            request.setMethod('GET');

            HttpResponse response = http.send(request);
            Boolean isValid = false;

            if (response.getStatusCode() == 200) {
                List<CreditScoreRecord> records = (List<CreditScoreRecord>) JSON.deserialize(response.getBody(), List<CreditScoreRecord>.class);
                for (CreditScoreRecord record : records) {
                    if (record.name == fullName && record.pan == panNumber) {
                        isValid = true;

                        // Update Credit Score field on the application
                        User_Credit_Card_Application__c updateApp = new User_Credit_Card_Application__c(
                            Id = appId,
                            Credit_Score__c = record.credit_score
                        );
                        update updateApp;

                        break;
                    }
                }
            } else {
                System.debug('PAN Verification API call failed. Status: ' + response.getStatus());
            }

            if (!isValid) {
                sendEmail(email, applicantName, 'PAN Verification Failed',
                    'Unfortunately, the details you provided did not match our records during the PAN verification process. ' +
                    'Please ensure that your name matches exactly as it appears on your official PAN card. ' +
                    'You may re-check the entered details and try submitting again.');
            } else {
                sendEmail(email, applicantName, 'PAN Verification: Successful',
                    'We are pleased to inform you that your PAN has been successfully verified. ' +
                    'This is an important step in the credit card application process. Your application is now under detailed review by our underwriting team. ' +
                    'We will be validating the income, employment status, and other submitted documents to ensure eligibility. ' +
                    'If all checks are cleared, we will proceed with credit card issuance. You can expect further communication within 2 to 4 business days.');
            }

        } catch (Exception e) {
            System.debug('Exception during PAN verification: ' + e.getMessage());
        }
    }

    private static void sendEmail(String toAddress, String fullName, String statusText, String reason) {
        if (String.isBlank(toAddress) || !Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', toAddress)) {
            System.debug('Invalid email address provided: ' + toAddress);
            return;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{toAddress});
        email.setSubject('Credit Card Application Status: ' + statusText);

        String body = 'Dear ' + fullName + ',\n\n' +
                      'Thank you for choosing Credit Squadz for your financial needs. We appreciate your interest in applying for one of our credit card products.\n\n' +
                      '📋 Application Summary:\n' +
                      '• Full Name: ' + fullName + '\n' +
                      '• Submission Date: ' + String.valueOf(Date.today()) + '\n' +
                      '• Current Status: ' + statusText + '\n\n';

        if (String.isNotBlank(reason)) {
            body += '⚠️ Important Note:\n' + reason + '\n\n';
        }

        body += 'Our dedicated verification team is actively reviewing your application and will reach out if any further information is required. ' +
                'We aim to complete all reviews within 2–4 working days, depending on the complexity and volume of applications.\n\n' +
                '💬 Need Help?\n' +
                'If you have any questions or concerns regarding your application, feel free to contact our support team by replying to this email or visiting our Help Center at support.creditsquadz.com.\n\n' +
                'We look forward to serving you.\n\n' +
                'Warm regards,\n' +
                'Credit Squadz Team\n' +
                '--------------------------\n' +
                'This is an automated message. Please do not reply directly to this email.';

        email.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    public class CreditScoreRecord {
        public String createdAt;
        public String name;
        public Integer rating;
        public Integer credit_score;
        public String pan;
        public String dob;
        public String id;
    }

    public class Request {
        @InvocableVariable(label='Full Name') public String fullName;
        @InvocableVariable(label='PAN Number') public String panNumber;
        @InvocableVariable(label='Annual Income') public Decimal annualIncome;
        @InvocableVariable(label='Email') public String email;
        @InvocableVariable(label='Phone') public String phone;
        @InvocableVariable(label='Residential Address') public String address;
        @InvocableVariable(label='Date of Birth') public Date dob;
        @InvocableVariable(label='Employment Status') public String employmentStatus;
    }

    public class Response {
        @InvocableVariable(label='Status') public String status;
        @InvocableVariable(label='Message') public String message;
        @InvocableVariable(label='Record Id') public Id recordId;
    }
}