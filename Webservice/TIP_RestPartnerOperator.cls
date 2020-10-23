/**
 * @author      Anna Filimonova
 * @date        12/03/2020
 * @group       DFS-SFDC
 * @description Facade class for partner REST API validations
 */
public with sharing class TIP_RestPartnerOperator {

    /** Map of partner record wrappers to process */
    Map<String, TIP_RestFactory.PartnerItem> partnerItems;
    
    /** Current state of error msg */
    private String errorMsg;

    /** TIP_RestPartnerValidator class that performs validations */
    private TIP_RestPartnerValidator validator;

    /**
     * @description Creates instance of operator.
     * @return TIP_RestPartnerOperator instance. 
     */
    public TIP_RestPartnerOperator() {
        partnerItems = new Map<String, TIP_RestFactory.PartnerItem>();
        validator = new TIP_RestPartnerValidator(CRM_Constants.WEB_SERVICE_ACTION_CREATE);
    }
    /**
     * @description Creates instance of operator FOR UPDATE.
     * @return TIP_RestPartnerOperator instance. 
     */
    public TIP_RestPartnerOperator(Set<String> externalIds) {
        partnerItems = new Map<String, TIP_RestFactory.PartnerItem>();
        validator = new TIP_RestPartnerValidator(CRM_Constants.WEB_SERVICE_ACTION_UPDATE);
        List<Account> accs = TIP_RestHelperUtil.getAllFieldsForAccounts(externalIds);
        validator.initForUpdate(accs);
    }

    /**
     * @description STEP 1. Initializes partnerItems map and marks the ones with duplicate ids.
     * @param partners List of wrappers to init.
     * @return - 
     */    
    public void init(List<TIP_Wrappers.PartnerData> partners) {
        Integer emptyExtIdCounter = 0;
        Integer duplicateExtIdCounter = 0;
        for (TIP_Wrappers.PartnerData partnerWrap : partners) {
            String key = String.isBlank(partnerWrap.externalId) ? String.valueOf(emptyExtIdCounter++) : partnerWrap.externalId;
            TIP_RestFactory.PartnerItem value;

            if (partnerItems.get(partnerWrap.externalId) != null) {
                key += duplicateExtIdCounter++;
                value = TIP_RestFactory.newItemWithDuplicateExtId(partnerWrap);
            } else {
                value = TIP_RestFactory.newItem(partnerWrap);
            }

            if (!sanityCheck(value)) {
                TIP_RestFactory.setError(value, errorMsg);
            }

            partnerItems.put(key, value);
        }
    }


    /**
     * @description Executes partner field validation.
     * @param -
     * @return -
     */
    public void validatePartnerFields() {
        Map<String, String> partnersWithInvalidFields = validator.validatePartnerFields(getValidItems().values());
        for (String partnerExtID : partnersWithInvalidFields.keySet()) {
            TIP_RestFactory.PartnerItem itemWithError = partnerItems.get(partnerExtID);
            TIP_RestFactory.setError(itemWithError, partnersWithInvalidFields.get(partnerExtID));
        }
    }

    /**
     * @description Checks duplicates against dapabase on working destinations and contacts.
     * @param -
     * @return -
     */
    public void validateDuplicates() {
        //validate if working destinations with same CMS code exist
        Map<String, String> partnersWithDuplicateWDs = validator.validateWDDuplicates();
        for (String partnerExtID : partnersWithDuplicateWDs.keySet()) {
            TIP_RestFactory.PartnerItem itemWithError = partnerItems.get(partnerExtID);
            TIP_RestFactory.setError(itemWithError, partnersWithDuplicateWDs.get(partnerExtID));
        }
        //validate contact external id duplicates
        Map<String, String> partnersWithDuplicateContacts = validator.validateContactDuplicates();
        for (String partnerExtID : partnersWithDuplicateContacts.keySet()) {
            TIP_RestFactory.PartnerItem itemWithError = partnerItems.get(partnerExtID);
            TIP_RestFactory.setError(itemWithError, partnersWithDuplicateContacts.get(partnerExtID));
        }
    }

    /**
     * @description To check if there are more records to validate.
     * @param - 
     * @return TRUE if there are records with no errors, FALSE if all records contain errors.
     */
    public Boolean hasValidRecords() {
        return getValidItems().size() > 0;
    }

    /**
     * @description Executes sanity check of given record and stores error msg after the check.
     * @param pItem item to check.
     * @return TRUE if the record passes validation, FALSE if the record doesn't pass validation.
     */
    private Boolean sanityCheck(TIP_RestFactory.PartnerItem pItem) {
        errorMsg = validator.doSanityCheck(pItem.record);
        return String.isBlank(errorMsg);
    }

    /**
     * @description Returns all records added to the container.
     * @param -
     * @return Map of all records by account external id.
     */
    public Map<String, TIP_RestFactory.PartnerItem> getAllItems() {
        return partnerItems;
    }

    /**
     * @description Returns only valid records added to the container.
     * @param -
     * @return Map of only valid records by account external id.
     */
    public Map<String, TIP_Wrappers.PartnerData> getValidItems() {
        Map<String, TIP_Wrappers.PartnerData> validItems = new Map<String, TIP_Wrappers.PartnerData>();
        for (String accountExtId : partnerItems.keySet()) {
            TIP_RestFactory.PartnerItem anItem = partnerItems.get(accountExtId);
            if (!anItem.isError) {
                validItems.put(accountExtId, anItem.record);
            }
        }
        return validItems;
    }

    /**
     * @description Mark partner item as invalid.
     * @param partnerExtId external id of invalid partner.
     * @param errorMsgs list of errors
     * @return Map of only valid records by account external id.
     */
    public void setErrorOnItem(String partnerExtId, List<String> errorMsgs) {
        TIP_RestFactory.PartnerItem itemWithError = partnerItems.get(partnerExtID);
        TIP_RestFactory.setError(itemWithError, String.join(errorMsgs, '. '));
    }

    /**
     * @description Mark partner item as invalid.
     * @param partnerExtId external id of invalid partner.
     * @param errorMsgs list of errors
     * @return Map of only valid records by account external id.
     */
    public void setFieldOnItem(String partnerExtId, String fieldLabel, String fieldValue) {
        TIP_RestFactory.PartnerItem anItem = partnerItems.get(partnerExtId);

        if (fieldLabel == 'sfId') {
            anItem.sfId = fieldValue;
        }
        if (fieldLabel == 'cmsCode') {
            for (TIP_Wrappers.WorkingDestinationData awd : anItem.record.workingDestinations) {
                if (String.isBlank(awd.cmsCode)) {
                    awd.cmsCode = fieldValue;
                }
            }
        }
    }

}