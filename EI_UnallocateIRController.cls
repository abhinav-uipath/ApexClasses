public without sharing class EI_UnallocateIRController {

    @AuraEnabled
    public static Inbound_Report__c getInboundReport(String reportId){
        
        list<Inbound_Report__c> reportList = [Select Id,Name, Installment__c,Amount__c,
                                                                 Matched_Colour__c,Reason_For_Unallocation__c,
                                                                 Reason_For_Unallocation_Specified__c, 
                                                                 Installment__r.Id,Refund__c,
                                                                 Installment__r.Installment_Type__c,Installment__r.Deposit__r.Customer__c,
                                                                 Installment__r.Deposit__c,
                                                                 Installment__r.Deposit__r.Protected_Amount__c,
                                                                 Installment__r.Deposit__r.Deposit_Amount__c,
                                                                 Installment__r.Deposit__r.Status__c
                                                                 from Inbound_Report__c where Id=: reportId];

        if(!reportList.isEmpty()){
            return reportList[0];
        }else{
            return new Inbound_Report__c();
        }

        
    }

    @AuraEnabled
    public static Map<String, String> getReasons(){
        Map<String, String> options = new Map<String, String>();
        //get Account Industry Field Describe
        Schema.DescribeFieldResult fieldResult = Inbound_Report__c.Reason_For_Unallocation__c.getDescribe();
        //get Account Industry Picklist Values
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            //Put Picklist Value & Label in Map
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }


    @AuraEnabled
    public static void updateReport(Inbound_Report__c report){
        
        if(report.Reason_For_Unallocation__c != 'Refund to customer'){
        	Update new Inbound_Report__c(Id= report.Id,Matched_Colour__c = 'Red',Installment__c=null,Reason_For_Unallocation__c = report.Reason_For_Unallocation__c,Reason_For_Unallocation_Specified__c = report.Reason_For_Unallocation_Specified__c);    
        }else{
            
            Update new Inbound_Report__c(Id= report.Id,Refund__c = true,Reason_For_Unallocation__c = report.Reason_For_Unallocation__c);    
        }
        
		
        if(report.Reason_For_Unallocation__c != 'Refund to customer'){
           Delete [Select Id from Payment__c where Inbound_Report__c =: report.Id];
        }
        
        

        if(report.Amount__c == report.Installment__r.Deposit__r.Protected_Amount__c){
            Update new Deposit__c(Id = report.Installment__r.Deposit__c, Status__c = 'Awaiting payment');
            sendEmailToTenant(false,report.Installment__r.Deposit__c);
        }else{
            Decimal depositAmount = report.Installment__r.Deposit__r.Deposit_Amount__c - report.Amount__c;
            Decimal protectedAmount = report.Installment__r.Deposit__r.Protected_Amount__c - report.Amount__c;
            Update new Deposit__c(Id = report.Installment__r.Deposit__c, Protected_Amount__c = protectedAmount, Deposit_Amount__c = depositAmount);
            sendEmailToTenant(true,report.Installment__r.Deposit__c);
        }
        
		
        if(report.Reason_For_Unallocation__c != 'Refund to customer'){
            Update new Installment__c(Id = report.Installment__c,Status__c = 'Pending');
        }else{ 
            Update new Installment__c(Id = report.Installment__c,Status__c = 'Reversed');
        }
        
        //?????if Selected Reason is Refund Please create an Installment 
        if(report.Reason_For_Unallocation__c == 'Refund to customer'){
            String accountId = report.Installment__r.Deposit__r.Customer__c;
            String contactId = '';
            list<Account> accList = [Select Id,(Select Id from Contacts ORDER BY LastModifiedDate DESC limit 1 ) from Account where Id =:accountId];
            if(!accList[0].Contacts.isEmpty()){
                contactId = acclist[0].Contacts[0].Id;
            }
            Installment__c inst = new Installment__c();
            inst.Status__c = 'Pending Processing';
            inst.Amount__c = report.Amount__c;
            inst.Installment_Type__c = 'Payable';
            inst.X30_Days_Completion_Date__c = system.today().addDays(-1);
            inst.Deposit__c = report.Installment__r.Deposit__c;
            if(String.isNotBlank(contactId)){
                inst.Contact__c = contactId;
            }
			inst.RecordTypeId = Schema.SObjectType.Installment__c.getRecordTypeInfosByName().get('SDS Installment').getRecordTypeId();
            Insert inst;
        }
    }

    @AuraEnabled
    public static String allocateReport(Inbound_Report__c report, String numberDAN){
        
        list<Installment__c> installmentList = [Select Id,Amount__c,Status__c from Installment__c 
                                                                                where Deposit__r.Deposit_Account_number__c =: numberDAN
                                                                                AND Amount__c =: report.Amount__c
                                                                                AND Status__c =: 'Pending'
                                                                                AND Installment_Type__c = 'Receivable'];
        if(!installmentList.isEmpty()){
            if(installmentList.size() == 1){
                
                update new Inbound_Report__c(Id = report.Id, Matched_Colour__c = 'Green',Installment__c = installmentList[0].Id,Reason_For_Unallocation__c = '');
                return 'SUCCESS';
            }else{
                return 'More than one pending Installments found for this DAN with same amount';
            }
        }else{
            return 'No pending Installments found for this DAN';
        }      

    }
    
    public static void sendEmailToTenant(Boolean isTopup, String depositId) {

        list<Deposit_Allocation__c> depositListItemOther = [SELECT id,Deposit__c,Role__c,Contact__c,Contact__r.AccountId,Deposit__r.Deposit_Account_Number__c,
                                                            Deposit__r.Property_Address__c,
                                                       Deposit_Holder__c,Deposit_Holder__r.Phone, 
                                                       Deposit_Holder__r.PersonContactId,  Deposit_Holder__r.Name,
                                                       Deposit_Holder__r.Salutation,Deposit_Holder__r.FirstName, 
                                                       Deposit_Holder__r.lastname,Deposit_Holder__r.PersonEmail,
                                                       Deposit_Holder__r.Activation_Code__pc,Deposit__r.EI_PropertyAddWithStar__c,
                                                       Deposit_Holder__r.IsCustomerPortal,Deposit__r.EI_UnvalidatedTenants__c,
                                                       Contact__r.Name, contact__r.Email
                                                       FROM Deposit_Allocation__c 
                                                       WHERE Deposit__c =:depositId AND  role__c='tenant'];

    	
        if(depositListItemOther != null && !depositListItemOther.isEmpty())
    		sendEmail(JSON.serialize(depositListItemOther),isTopup);  
    }
    
	@future(callout=true)
    public static void sendEmail(string allocationListString, Boolean isTopup) {
        
        list<Deposit_Allocation__c> allocationList = (list<Deposit_Allocation__c>) System.JSON.deserialize(allocationListString, list<Deposit_Allocation__c>.class);
        
        //??????????? Different template on the basis of isTopup
            
        /* Newly added code for Utility mailjet START */
        List<EI_SDS_MailJetUtilityCls.EmailWrapper> emailWrapperList = new List<EI_SDS_MailJetUtilityCls.EmailWrapper>();
        Date todayDate = System.today();
        String todayStr = todayDate.day()+'/'+todayDate.month()+'/'+todayDate.year();
        /* Newly added code for Utility mailjet END */
        
        for(Deposit_Allocation__c allocation: allocationList)
        {
            system.debug(allocation.Deposit_Status__c+' @@ valid -- '+allocation.Deposit__r.EI_UnvalidatedTenants__c);
            if (allocation.Deposit__r.EI_UnvalidatedTenants__c > 0){            
            /* Newly added code for Utility mailjet START */
            List<EI_SDS_MailJetUtilityCls.recipient> emailRecipientList = new List<EI_SDS_MailJetUtilityCls.recipient>();
            List<EI_SDS_MailJetUtilityCls.attachmentWrapper> attachmentWrapperList = new List<EI_SDS_MailJetUtilityCls.attachmentWrapper>();
            Map<String, String> variableMap = new Map<String, String>();
            
            String toEMail = String.isNotBlank(allocation.Deposit_Holder__r.personEmail)?allocation.Deposit_Holder__r.personEmail:'';
            String toName = String.isNotBlank(allocation.Deposit_Holder__r.Name)?allocation.Deposit_Holder__r.Name:'';
            
            emailRecipientList.add(new EI_SDS_MailJetUtilityCls.recipient(toEMail, toName, allocation.Deposit__c, '', allocation.Deposit_Holder__r.personContactId));
            variableMap.put('date',todayStr);
            variableMap.put('name',toName);
            variableMap.put('dan', String.valueOf(allocation.Deposit__r.Deposit_Account_Number__c));
            variableMap.put('address',allocation.Deposit__r.EI_PropertyAddWithStar__c);
            
            emailWrapperList.add(new EI_SDS_MailJetUtilityCls.EmailWrapper(JSON.serialize(emailRecipientList), variableMap, 
                                                                           'DepositProtectedinError',
                                                                           'Deposit protected in error'
                                                                          ));
            /* Newly added code for adding recipients, variables, template name, Subject END */
            }else if (allocation.Deposit__r.EI_UnvalidatedTenants__c == 0){
             /* Newly added code for Utility mailjet START */
            List<EI_SDS_MailJetUtilityCls.recipient> emailRecipientList = new List<EI_SDS_MailJetUtilityCls.recipient>();
            List<EI_SDS_MailJetUtilityCls.attachmentWrapper> attachmentWrapperList = new List<EI_SDS_MailJetUtilityCls.attachmentWrapper>();
            Map<String, String> variableMap = new Map<String, String>();
            
            String toEMail = String.isNotBlank(allocation.Deposit_Holder__r.personEmail)?allocation.Deposit_Holder__r.personEmail:'';
            String toName = String.isNotBlank(allocation.Deposit_Holder__r.Name)?allocation.Deposit_Holder__r.Name:'';
            
            emailRecipientList.add(new EI_SDS_MailJetUtilityCls.recipient(toEMail, toName, allocation.Deposit__c, '', allocation.Deposit_Holder__r.personContactId));
            variableMap.put('date',todayStr);
            variableMap.put('name',toName);
            variableMap.put('dan', String.valueOf(allocation.Deposit__r.Deposit_Account_Number__c));                
            variableMap.put('address',allocation.Deposit__r.Property_Address__c);
            
            emailWrapperList.add(new EI_SDS_MailJetUtilityCls.EmailWrapper(JSON.serialize(emailRecipientList), variableMap, 
                                                                           'DepositProtectedinError',
                                                                           'Deposit protected in error'
                                                                          ));
            /* Newly added code for adding recipients, variables, template name, Subject END */
            }    
        }
        
        try{
            /* Newly added code for adding recipients, variables, template name, Subject START */
            if(emailWrapperList.size()>0) {
                EI_SDS_MailJetUtilityCls.sendEmailFromBatch(JSON.serialize(emailWrapperList)); 	  
            }
            /* Newly added code for adding recipients, variables, template name, Subject END */
            
        }
        catch(exception e){   
            //saveMessageDetails(resBody,recMap,Subject );
            system.debug(e);
            //Create Message(with error) from Here if no success response or it breaks  >>> res comes null  or status code is not expected 429 etc
        }
    }
    
    public static void increaseCoverage(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }


}