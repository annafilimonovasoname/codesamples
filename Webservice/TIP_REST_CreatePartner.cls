/**
 * @author      Anna Filimonova
 * @date        10/03/2020
 * @group       DFS-SFDC
 * @description Webservice class for partner CREATE and UPDATE
 */

@RestResource(UrlMapping='/CreatePartner/*')
global with sharing class TIP_REST_CreatePartner {

    private static String SOURCE_CHANNEL;
    private static Boolean sendMail = false;

    private static String action;
    /** Response wrapper to return to callout */
    public static List<TIP_Wrappers.PartnerRestResponse> response;

    /**
     * @description Method to process POST request and insert Accounts
     * @param channel name
     * @param partners received partners information
     * @return JSON response that list of objects with fields ExternalID, SFID, Status and Message. 
     */
    @HttpPost
    global static List<TIP_Wrappers.PartnerRestResponse> doPost(String channel, Boolean sendEmail, List<TIP_Wrappers.PartnerData> data) {
        action = CRM_Constants.WEB_SERVICE_ACTION_CREATE;
        SOURCE_CHANNEL = channel;
        if (sendEmail != null) {
            sendMail = sendEmail;
        }
        TIP_CMSCodeGenerator.init(SOURCE_CHANNEL);

        response = new List<TIP_Wrappers.PartnerRestResponse>();

        if (data == null || data.isEmpty()) {
            response.add(
                new TIP_Wrappers.PartnerRestResponse(CRM_Constants.MISSING_DATA, '', '', '', '')
            );
            return response;
        }

        TIP_RestPartnerOperator validator = new TIP_RestPartnerOperator();
        handleRequest(data, validator);

        return response;
    }

    /**
     * @description Method to process POST request and update Accounts.
     * Update operation may include creation of new working destinations and contacts as this is an update for partner.
     * @param channel name
     * @param partners received partners information
     * @return JSON response that list of objects with fields ExternalID, SFID, Status and Message. 
     */
    @HttpPut
    global static List<TIP_Wrappers.PartnerRestResponse> doPut(String channel, Boolean sendEmail, List<TIP_Wrappers.PartnerData> data) {
        action = CRM_Constants.WEB_SERVICE_ACTION_UPDATE;
        if (sendEmail != null) {
            sendMail = sendEmail;
        }
        response = new List<TIP_Wrappers.PartnerRestResponse>();
        TIP_CMSCodeGenerator.init(channel);

        if (data == null || data.isEmpty()) {
            response.add(
                new TIP_Wrappers.PartnerRestResponse(CRM_Constants.MISSING_DATA, '', '', '', '')
            );
            return response;
        }

        Set<String> externalIds = new Set<String>();
        for (TIP_Wrappers.PartnerData pData : data) {
            if (!String.isBlank(pData.externalId)) {
                externalIds.add(pData.externalId);
            }
        }

        TIP_RestPartnerOperator validator = new TIP_RestPartnerOperator(externalIds);
        handleRequest(data, validator);

        return response;
    }

    private static void handleRequest(List<TIP_Wrappers.PartnerData> partners, TIP_RestPartnerOperator validator) {

        validator.init(partners);
        validator.validatePartnerFields();
        validator.validateDuplicates();

        Map<String, Account> accountsByExtID = new Map<String, Account>();
        Map<String, List<TIP_Working_Destination__c>> wdsByAccExtId = new Map<String, List<TIP_Working_Destination__c>>();
        Map<String, List<Contact>> contactsByAccExtId = new Map<String, List<Contact>>();

        if (validator.hasValidRecords()) {

            for (TIP_Wrappers.PartnerData validPartner : validator.getValidItems().values()) {
                Account partner = TIP_RestFactory.createAccount(validPartner);
                if (!String.isEmpty(SOURCE_CHANNEL)) {
                partner.TIP_Channel__c = SOURCE_CHANNEL;
                }
                partner.TIP_Send_Email__c = sendMail;
                accountsByExtID.put(validPartner.externalId, partner);

                List<TIP_Working_Destination__c> wdRecords = new List<TIP_Working_Destination__c>();
                if (validPartner.workingDestinations != null) {
                    for (TIP_Wrappers.WorkingDestinationData wdWrap : validPartner.workingDestinations) {
                        TIP_Working_Destination__c wdRecord = TIP_RestFactory.createWorkingDestination(validPartner.externalId, wdWrap);
                        wdRecords.add(wdRecord);
                    }
                }
                wdsByAccExtId.put(validPartner.externalId, wdRecords);

                List<Contact> contactRecords = new List<Contact>();
                if (validPartner.contacts != null) {
                    for (TIP_Wrappers.ContactData contactWrap : validPartner.contacts) {
                        Contact contactRecord = TIP_RestFactory.createContact(contactWrap, validPartner.partnerType);
                        contactRecords.add(contactRecord);
                    }
                }
                contactsByAccExtId.put(validPartner.externalId, contactRecords);

            }

            //Database.SaveResult[] accountInsertResult = Database.insert(accountsByExtID.values(), false);
            //Database.UpsertResult[] accountInsertResult = Database.upsert(accountsByExtID.values(), 
                //Account.TIP_Account_External_ID__c, false);
            DmlResultList accountResult = performOperation(accountsByExtID.values());
            //for (Integer resultCount = 0; resultCount < accountInsertResult.size(); resultCount++) {
            for (Integer resultCount = 0; resultCount < accountResult.genResults.size(); resultCount++) {
                //Database.UpsertResult sr = accountInsertResult[resultCount]; 
                DmlResult sr = accountResult.genResults[resultCount];
                Account accRecord = accountsByExtID.values()[resultCount];
                String partnerExtID = accRecord.TIP_Account_External_Id__c;
                if (!sr.isSuccess()) {
                    List<String> errorMsgs = new List<String>();
                    for(Database.Error err : sr.getErrors()) {
                        errorMsgs.add(err.getStatusCode() + ': ' + err.getMessage());
                    }
                    //log error for response
                    validator.setErrorOnItem(partnerExtID, errorMsgs);
                    //remove from insert
                    wdsByAccExtId.remove(partnerExtID);
                    contactsByAccExtId.remove(partnerExtID);
                } else {
                    //populate ID field
                    for (TIP_Working_Destination__c relatedWD : wdsByAccExtId.get(partnerExtID)) {
                        //populate MD relationship for child record
                        relatedWD.Account__c = accRecord.Id;
                    }
                    for (Contact relatedContact : contactsByAccExtId.get(partnerExtID)) {
                        relatedContact.AccountId = accRecord.Id;
                    }
                    //populate in wrapper for response
                    validator.setFieldOnItem(partnerExtID, 'sfId', accRecord.Id);
                }
            }

            List<TIP_Working_Destination__c> wdRecordsToInsert = new List<TIP_Working_Destination__c>();
            List<Contact> contactRecordsToInsert = new List<Contact>();
            for (String accountExtId : wdsByAccExtId.keySet()) {
                wdRecordsToInsert.addAll(wdsByAccExtId.get(accountExtId));
                contactRecordsToInsert.addAll(contactsByAccExtId.get(accountExtId));
            }
            //fail all if something is wrong
            //insert wdRecordsToInsert;
            System.debug('---wdRecordsToInsert: ' + wdRecordsToInsert);
            upsert wdRecordsToInsert External_ID__c;
            //populate cms codes in the initial request
            List<TIP_Working_Destination__c> wdsAfterInsert = [
                SELECT Account__r.TIP_Account_External_Id__c, CMS_Code__c 
                FROM TIP_Working_Destination__c
                WHERE Id IN :wdRecordsToInsert
            ];
            for (TIP_Working_Destination__c wdAfterInsert : wdsAfterInsert) {
                validator.setFieldOnItem(wdAfterInsert.Account__r.TIP_Account_External_Id__c, 'cmsCode', wdAfterInsert.CMS_Code__c);
            }
            //insert contactRecordsToInsert;
            upsert contactRecordsToInsert TIP_External_ID__c;
            //how to handle????
        }

        response = prepareResponse(validator.getAllItems().values());
    }

    private static DmlResultList performOperation(List<Account> accountValues) {
        if (action == CRM_Constants.WEB_SERVICE_ACTION_CREATE) {
            return new DmlResultList(Database.insert(accountValues, false));
        }
        if (action == CRM_Constants.WEB_SERVICE_ACTION_UPDATE) {
            return new DmlResultList(Database.upsert(accountValues, Account.TIP_Account_External_ID__c, false));
        }
        return null;
    }

    private static List<TIP_Wrappers.PartnerRestResponse> prepareResponse(List<TIP_RestFactory.PartnerItem> validatorItems) {
        List<TIP_Wrappers.PartnerRestResponse> prepareReponses = new List<TIP_Wrappers.PartnerRestResponse>();
        for (TIP_RestFactory.PartnerItem item : validatorItems) {
            System.debug('===errors: ' + item.errMesg);
            String cms = (item.record.workingDestinations == null || item.record.workingDestinations.isEmpty()) ? '' : item.record.workingDestinations.get(0).cmsCode;
            prepareReponses.add(
                new TIP_Wrappers.PartnerRestResponse(
                    item.isError ? CRM_Constants.RESPONSE_ERROR.toUpperCase() : CRM_Constants.RESPONSE_SUCCESS.toUpperCase(),
                    item.record.externalId,
                    item.sfId,
                    cms,
                    item.errMesg
                )
            );
        }
        return prepareReponses;
    }

    private class DmlResult {
        Id recordId;
        Integer rowIndex;
        Boolean success;
        Database.Error[] errors;
        DmlResult(Boolean success, Id recordId, Database.Error[] errors, Integer rowIndex) {
            this.success = success;
            this.recordId = recordId;
            this.errors = errors;
            this.rowIndex = rowIndex;
        }

        public Boolean isSuccess() {
            return success;
        }
        public Database.Error[] getErrors() {
            return errors;
        }
    }
    private class DmlResultList {
        DmlResult[] genResults;
        DmlResultList(Database.SaveResult[] results) {
            genResults = new DmlResult[0];
            for(Database.SaveResult result: results) {
                genResults.add(new DmlResult(result.isSuccess(), result.getId(), result.getErrors(), genResults.size()));
            }
        }
        DmlResultList(Database.UpsertResult[] results) {
            genResults = new DmlResult[0];
            for(Database.UpsertResult result: results) {
                genResults.add(new DmlResult(result.isSuccess(), result.getId(), result.getErrors(), genResults.size()));
            }
        }
    // ... other result types
    }
}