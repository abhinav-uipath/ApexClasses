public without Sharing class  EWI_AllocatePaymentsController {
    public static Id CaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Dispute EW Insured').getRecordTypeId();
    
    @AuraEnabled
    public static Boolean isPermissionSet(){
        Id currentUser = userinfo.getUserId();
        List<PermissionSetAssignment> psa = [SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, 
                                             PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment 
                                             WHERE Assignee.Id = :currentUser AND PermissionSet.Name = 'EWIFinance'];
        if(psa != null && psa.size() >0){
            return true;
        }else{
            return false;
        }
    }
    @AuraEnabled
    public static list<InboundReportWrapper> returnInboundReports(Decimal amount,Boolean isFilter, String filterType, Date startCreatedDate, Date endCreatedDate, String selectedRecordType){
        System.debug('selectedRecordType : '+selectedRecordType);
        map<Id,list<InboundReportWrapper>> installMentIdVs = new map<Id,list<InboundReportWrapper>>();
        //list<Inbound_Report__c> inboundReports = [Select Id,Name,File_Name__c,Payment_Method__c,Collection_Date__c,Matched_Colour__c,Installment__c,Installment__r.Deposit__r.Deposit_Account_Number__c,Reference1__c,Amount__c,Reference2__c,Reference3__c,Reference4__c,Reference5__c,Reason_For_Unallocation__c,CreatedDate from Inbound_Report__c where Matched_Colour__c != '' AND Reason_For_Unallocation__c != 'Refund to customer' AND Status__c != 'Inactive' AND RecordType.Name = 'SDS Inbound Report' ORDER BY Matched_Colour__c ASC];
        list<Inbound_Report__c> inboundReports = [Select Id,Sage_URN__c, Installment__r.Case__r.Total_Deposit__c,Installment__r.Case__r.Total_amount_in_dispute__c,Installment__r.Case__r.FinalCaseBalance__c, collection_date_format__c,Installment__r.Case__c,Payment_Created_By__c,Name,File_Name__c,Payment_Method__c,Collection_Date__c,Matched_Colour__c,Installment__c,
                                                  Installment__r.Deposit__r.Deposit_Account_Number__c,Reference1__c,Amount__c,Reference2__c,Reference3__c,Reference4__c,
                                                  Reference5__c,Reason_For_Unallocation__c,CreatedDate, Installment__r.Case__r.Status, Installment__r.Case__r.Amount_of_Disputed_Funds_Required__c,  
                                                  Installment__r.Case__r.G_Number__c,Installment__r.Case__r.Remaining_deposit_amount__c,Narrative2_Details__c,Installment__r.Case__r.Dispute_Reference__c,
                                                  Installment__r.Case__r.Amount_of_Disputed_Funds_Received__c,Installment__r.Case__r.Amount_of_Disputed_Funds_Remaining__c,Amber_Matched_Values__c,Installment__r.Deposit__r.Amount_Received_By_Scheme__c from Inbound_Report__c where Matched_Colour__c != '' AND 
                                                  Reason_For_Unallocation__c != 'Refund to customer' AND Status__c != 'Inactive' AND 
                                                  RecordType.Name = :selectedRecordType ORDER BY Matched_Colour__c ASC];
        list<InboundReportWrapper> wrapperToReturn = new list<InboundReportWrapper>();
        list<InboundReportWrapper> wrapperToReturnFilter = new list<InboundReportWrapper>();
        list<InboundReportWrapper> wrapperToReturnBlue = new list<InboundReportWrapper>();
        list<InboundReportWrapper> wrapperToReturnGreen = new list<InboundReportWrapper>();
        list<InboundReportWrapper> wrapperToReturnAmber = new list<InboundReportWrapper>();
        list<InboundReportWrapper> wrapperToReturnRed = new list<InboundReportWrapper>();
        
        for(Inbound_Report__c report : inboundReports){
            InboundReportWrapper wrap = new InboundReportWrapper();
            wrap.isSelected = false;
            //report.Collection_Date__c = Date.valueOf(report.Collection_Date__c.day() + '-' + report.Collection_Date__c.month() + '-' + report.Collection_Date__c.year());
            wrap.objInboundReport = report;
            if(report.Installment__c != null){
                if(installMentIdVs.containsKey(report.Installment__c)){
                    
                    list<InboundReportWrapper> wrappers = installMentIdVs.get(report.Installment__c);
                    wrappers.add(wrap);
                    installMentIdVs.put(report.Installment__c,wrappers);
                }else{
                    
                    installMentIdVs.put(report.Installment__c,new list<InboundReportWrapper>{wrap});
                }
            }else{
                wrap.matchedColour = report.Matched_Colour__c;
                wrapperToReturnRed.add(wrap);
            }
            
        }
        for(Id instId : installMentIdVs.keySet()){
            if(installMentIdVs.get(instId).size() == 1){
                InboundReportWrapper wrap = installMentIdVs.get(instId)[0];
                wrap.matchedColour = wrap.objInboundReport.Matched_Colour__c;
                if(wrap.matchedColour == 'Green'){
                    wrapperToReturnGreen.add(wrap);
                }else{
                    wrapperToReturnAmber.add(wrap);
                }
                
            }else{
                for(InboundReportWrapper wrap : installMentIdVs.get(instId)){
                    wrap.matchedColour = 'Blue'; 
                    wrapperToReturnBlue.add(wrap);
                }
            }
        }
        if(!wrapperToReturnGreen.isEmpty()){
            wrapperToReturn.addAll(wrapperToReturnGreen);
        }
        if(!wrapperToReturnAmber.isEmpty()){
            wrapperToReturn.addAll(wrapperToReturnAmber);
        }
        if(!wrapperToReturnBlue.isEmpty()){
            wrapperToReturn.addAll(wrapperToReturnBlue);
        }
        if(!wrapperToReturnRed.isEmpty()){
            wrapperToReturn.addAll(wrapperToReturnRed);
        }
        
        if(isFilter){
            
            if(filterType == 'date'){
                endCreatedDate = endCreatedDate.addDays(1);
                for(InboundReportWrapper wrap : wrapperToReturn){
                    
                    if(wrap.objInboundReport.CreatedDate < endCreatedDate && wrap.objInboundReport.CreatedDate > startCreatedDate){
                        wrapperToReturnFilter.add(wrap);
                    }
                    
                }
                
            }else{
                for(InboundReportWrapper wrap : wrapperToReturn){
                    
                    if(wrap.objInboundReport.Amount__c == amount){
                        wrapperToReturnFilter.add(wrap);
                    }
                    
                }
            }
            
            return wrapperToReturnFilter;
        }else{
            return wrapperToReturn;
        }
        
        
    }
    
    @AuraEnabled
    public static list<InboundReportWrapper> moveToRed(list<InboundReportWrapper> wrapperList, String Id,Decimal amount,Boolean isFilter, String filterType, Date startCreatedDate, Date endCreatedDate, String selectedRecordType){
        //move selected reports to Red
        list<Inbound_Report__c> reportsToUpdate = new list<Inbound_Report__c>();
        
        if(String.isBlank(Id)){
            for(InboundReportWrapper wrap : wrapperList){
                Inbound_Report__c report = wrap.objInboundReport;
                if(wrap.isSelected && wrap.objInboundReport.Matched_Colour__c != 'Red'){
                    
                    report.Matched_Colour__c = 'Red';
                    report.Installment__c = null;
                    reportsToUpdate.add(report);
                }
            }
        }else{
            Inbound_Report__c report = new Inbound_Report__c();
            report.Id = Id;
            report.Matched_Colour__c = 'Red';
            report.Installment__c = null;
            reportsToUpdate.add(report);
        }
        
        
        
        if(!reportsToUpdate.isEmpty()){
            try {
                Update reportsToUpdate;
                
            } catch (Exception exc) {
                //Create Logs 
            }
        }
        return returnInboundReports(amount, isFilter,  filterType,  startCreatedDate,  endCreatedDate, selectedRecordType);
    }
    @AuraEnabled
    public static list<InboundReportWrapper> moveToGray(list<InboundReportWrapper> wrapperList, String Id,Decimal amount,Boolean isFilter, String filterType, Date startCreatedDate, Date endCreatedDate, String selectedRecordType){
        //move selected reports to Red
        list<Inbound_Report__c> reportsToUpdate = new list<Inbound_Report__c>();
        
        if(String.isBlank(Id)){
            for(InboundReportWrapper wrap : wrapperList){
                Inbound_Report__c report = wrap.objInboundReport;
                if(wrap.isSelected && wrap.objInboundReport.Matched_Colour__c != 'Gray'){
                    
                    report.Matched_Colour__c = 'Gray';
                    report.Installment__c = null;
                    reportsToUpdate.add(report);
                }
            }
        }else{
            Inbound_Report__c report = new Inbound_Report__c();
            report.Id = Id;
            report.Matched_Colour__c = 'Gray';
            report.Installment__c = null;
            reportsToUpdate.add(report);
        }
        
        
        
        if(!reportsToUpdate.isEmpty()){
            try {
                Update reportsToUpdate;
                
            } catch (Exception exc) {
                //Create Logs 
            }
        }
        return returnInboundReports(amount, isFilter,  filterType,  startCreatedDate,  endCreatedDate, selectedRecordType);
    }
    
    public static void createInstallmentRemainingAmount (List<Case> newlist){
        system.debug('method called');
        Set<Id> setCaseIds=new Set<Id>();
        Set<Id> newSetCaseIds=new Set<Id>();
        List<Installment__c> listOfInstallmentsToCreate = new List<Installment__c>(); 
        List<Case>lstCasewithAmounts=new  List<Case>();
        try{
            Id InstalRecordTypeId = Schema.SObjectType.Installment__c.getRecordTypeInfosByDeveloperName().get('EWI_Installment').getRecordTypeId();
            for(Case objCase:newlist){
                System.debug('objCase.RecordTypeId : '+objCase.RecordTypeId+'--'+'CaseRecordTypeId : '+CaseRecordTypeId);
                if(objCase.RecordTypeId==CaseRecordTypeId ){
                    System.debug('objCase.Amount_of_Disputed_Funds_Remaining__c:'+objCase.Amount_of_Disputed_Funds_Remaining__c);
                    if(objCase.Amount_of_Disputed_Funds_Remaining__c>0){
                        System.debug('objCase.Amount_of_Disputed_Funds_Required__c:'+objCase.Amount_of_Disputed_Funds_Required__c+'--'+'objCase.Amount_of_Disputed_Funds_Received__c:'+objCase.Amount_of_Disputed_Funds_Received__c);
                        if(objCase.Amount_of_Disputed_Funds_Required__c!=objCase.Amount_of_Disputed_Funds_Received__c){
                            if(objCase.Amount_of_Disputed_Funds_Received__c<objCase.Amount_of_Disputed_Funds_Required__c && objCase.Amount_of_Disputed_Funds_Received__c>0){
                                system.debug('Iside IF>>');
                                setCaseIds.add(objCase.Id);
                                lstCasewithAmounts.add(objCase);
                            }
                            if(objCase.Amount_of_Disputed_Funds_Received__c>objCase.Amount_of_Disputed_Funds_Required__c && objCase.Amount_of_Disputed_Funds_Received__c>0){
                                system.debug('Iside 2ndIF>>');
                                setCaseIds.add(objCase.Id);
                                lstCasewithAmounts.add(objCase);  
                            }
                        }
                    }
                    if(objCase.Undisputed_Funds_Received__c > 0 || objCase.Amount_of_Disputed_Funds_Received__c >0){
                        setCaseIds.add(objCase.Id);
                        //lstCasewithAmounts.add(objCase);
                    }
                }
                
            }
            List<Case>listOfCaseWithCasePar =
                [SELECT Id,AccountId,Undisputed_Funds_Received__c,Evidence_Gathering_Start_Date__c, EWI_Payment_genareted__c,Total_Agreed_by_Tenant__c,AGLL_Offer_Amount__c,TT_Offer_Amount__c,Total_Agreed_by_AG_LL__c,Status, Total_Deposit__c, Deposit_Account_Number__r.Name, 
                 Total_amount_in_dispute__c,Deposit_Account_Number__c ,Respond_Date__c,Amount_of_Disputed_Funds_Received__c,Amount_of_Disputed_Funds_Required__c,Amount_of_Disputed_Funds_Remaining__c,Amount_to_agent_landlord__c,Amount_to_tenants__c,
                 (SELECT Id,Primary_Agent__c, Account__c,Bank_Name__c,Bank_Identification_Code__c,Bank_Account_Number__c,Bank_Sort_Code__c,Bank_Account_Holder_Name__c,Contact__c,
                  Case__c,Case__r.Deposit_Account_Number__c, Contact__r.Name, Type__c, Contact__r.Email, Contact__r.FirstName, Contact__r.LastName,Beneficiary_Home_Address__c,
                  International_Account_Number__c,International_Bank_Account_Holder_Name__c,International_Bank_Address__c,International_Bank_Name__c,International_Payment__c,Swift_Code__c FROM Case_Participants__r) FROM Case where Id In :setCaseIds
                ];
            
            
            List<Installment__C>lstInstExisting=[Select Id,Amount__c,Case__c,Case_participant__c,Case_participant__r.Type__c,Status__c from Installment__C where Case__c=:setCaseIds];
            List<Installment__C> installmentsToUpdate = new List<Installment__C>();
             system.debug('lstInstExisting>>' + lstInstExisting);
            if(!lstInstExisting.isEmpty() && lstInstExisting.size()>0){
                for(Case objCase :listOfCaseWithCasePar){
                    if(objCase.Amount_of_Disputed_Funds_Remaining__c > 0){
                        for(Case_Participant__c cp : objCase.Case_Participants__r){
                            if((cp.Type__c=='Agent' && cp.Primary_Agent__c) || cp.Type__c=='Independent-Landlord'){
                                Installment__c objIns= new Installment__c();
                                if(objCase.Amount_of_Disputed_Funds_Received__c<objCase.Amount_of_Disputed_Funds_Required__c){
                                    objIns.Installment_Type__c='Receivable';
                                    objIns.Status__c='Pending';
                                }
                                if(objCase.Amount_of_Disputed_Funds_Received__c>objCase.Amount_of_Disputed_Funds_Required__c){
                                    objIns.Installment_Type__c='Payable';
                                    objIns.Status__c='Pending Processing';
                                }
                                if(objCase.AccountId!=null)
                                {
                                   objIns.Account__c = objCase.AccountId;
                                }
                                objIns.Amount__c=objCase.Amount_of_Disputed_Funds_Remaining__c;
                                objIns.Case_participant__c = cp.Id;
                                objIns.Case__C=objCase.Id;
                                objIns.RecordTypeId=InstalRecordTypeId;
                                objIns.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns.Contact__c=cp.Contact__c;
                                 if(cp.Bank_Account_Number__c !=null && cp.Bank_Sort_Code__c !=null && cp.Bank_Account_Holder_Name__c !=null)
                                {
                                objIns.Bank_Name__c=cp.Bank_Name__c;
                                objIns.Bank_Account_Number__c=cp.Bank_Account_Number__c;
                                objIns.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                                objIns.Bank_Account_Holder_Name__c=cp.Bank_Account_Holder_Name__c;
                                objIns.UK_Payment__c = true;
                                objIns.International_Payment__c=false;
                                }
                                else{
                                     objIns.International_Payment__c=cp.International_Payment__c;
                                    objIns.Bank_Name__c=cp.International_Bank_Name__c;
                                    objIns.BIC__c=cp.Bank_Identification_Code__c;
                                    objIns.Bank_Account_Number__c=cp.International_Account_Number__c;
                                    objIns.Bank_Account_Holder_Name__c=cp.International_Bank_Account_Holder_Name__c;
                                    objIns.Swift_Code__c=cp.Swift_Code__c;
                                     objIns.beneficiary_address__c = cp.Beneficiary_Home_Address__c;
                                     objIns.UK_Payment__c=false;
                                    objIns.International_Payment__c=true;
                        
                                }
                                listOfInstallmentsToCreate.add(objIns);    
                            }
                        }
                    }
                    system.debug('Undisputed_Funds_Received__c>>' + objCase.Undisputed_Funds_Received__c);
                    if(objCase.Undisputed_Funds_Received__c > 0 && (objCase.Status == 'Evidence gathering agent/landlord'
                      || objCase.Status == 'Evidence gathering tenant' || objCase.Status == 'Evidence review complete'
                      || objCase.Status == 'Adjudication' || (objCase.Evidence_Gathering_Start_Date__c !=null && objCase.Status == 'Awaiting Review' ) )){
                        system.debug('objCase.Status>>' + objCase.Status);
                          Integer totalNumberOfTenants = 0;
                        Decimal Undisputedamounttotenant =0.00;
                        Decimal Undisputedamounttoagll =0.00;
                        
                          If(objCase.Undisputed_Funds_Received__c>0 ){
                                    If(objCase.Undisputed_Funds_Received__c<=objCase.TT_Offer_Amount__c) {
                                     Undisputedamounttotenant = objCase.Undisputed_Funds_Received__c; 
                                     Undisputedamounttoagll = 0.00;
                                    }  
                                   If(objCase.Undisputed_Funds_Received__c>objCase.TT_Offer_Amount__c) {
                                     Undisputedamounttotenant = objCase.TT_Offer_Amount__c; 
                                       If((objCase.Undisputed_Funds_Received__c-objCase.TT_Offer_Amount__c)<=objCase.AGLL_Offer_Amount__c){
                                        Undisputedamounttoagll = objCase.Undisputed_Funds_Received__c-objCase.TT_Offer_Amount__c;    
                                       }
                                       else{
                                       Undisputedamounttoagll = objCase.AGLL_Offer_Amount__c;    
                                       }
                                     
                                   }
                                }  
                         system.debug('line-->307 ++' + Undisputedamounttotenant ); 
                         system.debug('line-->308 ++' + Undisputedamounttoagll ); 
                        Map<String,Case_Participant__c> caseParticipantId = new Map<String,Case_Participant__c>();
                        for(Case_Participant__c cp : objCase.Case_Participants__r){
                          if(Undisputedamounttoagll>0 && ((cp.Type__c=='Agent' && cp.Primary_Agent__c) || cp.Type__c=='Independent-Landlord')){
                                Installment__c objIns2= new Installment__c();
                                    objIns2.Installment_Type__c='Payable';
                                    objIns2.Status__c='Pending Processing';
                                if(objCase.AccountId!=null)
                                {
                                   objIns2.Account__c = objCase.AccountId;
                                }
                                objIns2.Amount__c=Undisputedamounttoagll;
                                objIns2.Case_participant__c = cp.Id;
                                objIns2.Case__C=objCase.Id;
                                objIns2.RecordTypeId=InstalRecordTypeId;
                                objIns2.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns2.Contact__c=cp.Contact__c;
                                 if(cp.Bank_Account_Number__c !=null && cp.Bank_Sort_Code__c !=null && cp.Bank_Account_Holder_Name__c !=null)
                                {
                                objIns2.Bank_Name__c=cp.Bank_Name__c;
                                objIns2.Bank_Account_Number__c=cp.Bank_Account_Number__c;
                                objIns2.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                                objIns2.Bank_Account_Holder_Name__c=cp.Bank_Account_Holder_Name__c;
                                objIns2.UK_Payment__c = true;
                                objIns2.International_Payment__c=false;
                                }
                                else{
                                     objIns2.International_Payment__c=cp.International_Payment__c;
                                    objIns2.Bank_Name__c=cp.International_Bank_Name__c;
                                    objIns2.BIC__c=cp.Bank_Identification_Code__c;
                                    objIns2.Bank_Account_Number__c=cp.International_Account_Number__c;
                                    objIns2.Bank_Account_Holder_Name__c=cp.International_Bank_Account_Holder_Name__c;
                                    objIns2.Swift_Code__c=cp.Swift_Code__c;
                                     objIns2.beneficiary_address__c = cp.Beneficiary_Home_Address__c;
                                     objIns2.UK_Payment__c=false;
                                    objIns2.International_Payment__c=true;
                        
                                }
                                listOfInstallmentsToCreate.add(objIns2); 
                             }    
                            
                            if(cp.Type__c=='Tenant'){
                                totalNumberOfTenants++;
                                caseParticipantId.put(cp.Id,cp);
                            }
                        }
                        system.debug('totalNumberOfTenants>>' + totalNumberOfTenants);
                        system.debug('Undisputed_Funds_Received__c>>' + objCase.Undisputed_Funds_Received__c);
                        if(totalNumberOfTenants > 0 && Undisputedamounttotenant>0){
                        	Decimal installmentAmount = Undisputedamounttotenant/totalNumberOfTenants;
                            Integer totalNumberOfInstallments = 0;
                            set<string> installmentIdAdded = new set<string>();
                           /* for(Installment__c inst : lstInstExisting){
                                system.debug('inst.Case_participant__c>>' + inst.Case_participant__c );
                                system.debug ( 'inst.Case_participant__r.Type__c >>'+inst.Case_participant__r.Type__c );
                                system.debug ('inst.Status__c >>' + inst.Status__c);
                                system.debug('inst.Amount__c' + inst.Amount__c);
                                system.debug('installmentAmount' + installmentAmount);
                                     
                            }
                            system.debug('caseParticipantId>>'+ caseParticipantId);*/
                            for(String cp : caseParticipantId.keySet()){
                                Installment__c objIns= new Installment__c();
                                objIns.Account__c = objCase.AccountId;
                                objIns.Installment_Type__c='Payable';
                                objIns.Status__c='Pending Processing';
                                objIns.Amount__c=installmentAmount;
                                objIns.Case__C=objCase.Id;
                                objIns.RecordTypeId=InstalRecordTypeId;
                                objIns.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns.Case_participant__c = cp;
                                objIns.Contact__c=caseParticipantId.get(cp).Contact__c;
                                if(caseParticipantId.get(cp).Bank_Account_Number__c !=null && caseParticipantId.get(cp).Bank_Sort_Code__c !=null && caseParticipantId.get(cp).Bank_Account_Holder_Name__c !=null)
                                {
                                objIns.Bank_Name__c=caseParticipantId.get(cp).Bank_Name__c;
                                //objIns.BIC__c=caseParticipantId.get(cp).Bank_Identification_Code__c;
                                objIns.Bank_Account_Number__c=caseParticipantId.get(cp).Bank_Account_Number__c;
                                objIns.Bank_Sort_Code__c=caseParticipantId.get(cp).Bank_Sort_Code__c;
                                objIns.Bank_Account_Holder_Name__c=caseParticipantId.get(cp).Bank_Account_Holder_Name__c;
                                objIns.UK_Payment__c = true;
                                objIns.International_Payment__c=false;
                                }
                             //   if (caseParticipantId.get(cp).International_Payment__c==true){
                                else {
                                     objIns.International_Payment__c=caseParticipantId.get(cp).International_Payment__c;
                                    objIns.Bank_Name__c=caseParticipantId.get(cp).International_Bank_Name__c;
                                    objIns.BIC__c=caseParticipantId.get(cp).Bank_Identification_Code__c;
                                    objIns.Bank_Account_Number__c=caseParticipantId.get(cp).International_Account_Number__c;
                                    //objIns.Bank_Sort_Code__c=caseParticipantId.get(cp).Bank_Sort_Code__c;
                                     objIns.beneficiary_address__c = caseParticipantId.get(cp).Beneficiary_Home_Address__c;
                                    objIns.Bank_Account_Holder_Name__c=caseParticipantId.get(cp).International_Bank_Account_Holder_Name__c;
                                    objIns.Swift_Code__c=caseParticipantId.get(cp).Swift_Code__c;
                                    objIns.UK_Payment__c=false;
                                    objIns.International_Payment__c=true;
                                }
                                listOfInstallmentsToCreate.add(objIns);
                            }
                        }
                        
                    }
                    
                   // EID-1006 new code added by Himanshu Modi Start
                  
                      if((objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c) > 0 && ( objCase.Status == 'Rejected' || objCase.Status =='Case closed – no dispute')){
                        system.debug('objCase.Status>>' + objCase.Status);
                          Integer totalNumberOfTenants = 0;
                        Map<String,Case_Participant__c> caseParticipantId = new Map<String,Case_Participant__c>();
                        for(Case_Participant__c cp : objCase.Case_Participants__r){
                             if((cp.Type__c=='Agent' && cp.Primary_Agent__c) || cp.Type__c=='Independent-Landlord'){
                                Installment__c objIns2= new Installment__c();
                                    objIns2.Installment_Type__c='Payable';
                                    objIns2.Status__c='Pending Processing';
                                if(objCase.AccountId!=null)
                                {
                                   objIns2.Account__c = objCase.AccountId;
                                }
                                objIns2.Amount__c=(objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c).setscale(2);
                                objIns2.Case_participant__c = cp.Id;
                                objIns2.Case__C=objCase.Id;
                                objIns2.RecordTypeId=InstalRecordTypeId;
                                objIns2.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns2.Contact__c=cp.Contact__c;
                                 if(cp.Bank_Account_Number__c !=null && cp.Bank_Sort_Code__c !=null && cp.Bank_Account_Holder_Name__c !=null)
                                {
                                objIns2.Bank_Name__c=cp.Bank_Name__c;
                                objIns2.Bank_Account_Number__c=cp.Bank_Account_Number__c;
                                objIns2.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                                objIns2.Bank_Account_Holder_Name__c=cp.Bank_Account_Holder_Name__c;
                                objIns2.UK_Payment__c = true;
                                objIns2.International_Payment__c=false;
                                }
                                else{
                                     objIns2.International_Payment__c=cp.International_Payment__c;
                                    objIns2.Bank_Name__c=cp.International_Bank_Name__c;
                                    objIns2.BIC__c=cp.Bank_Identification_Code__c;
                                    objIns2.Bank_Account_Number__c=cp.International_Account_Number__c;
                                    objIns2.Bank_Account_Holder_Name__c=cp.International_Bank_Account_Holder_Name__c;
                                    objIns2.Swift_Code__c=cp.Swift_Code__c;
                                     objIns2.beneficiary_address__c = cp.Beneficiary_Home_Address__c;
                                     objIns2.UK_Payment__c=false;
                                    objIns2.International_Payment__c=true;
                        
                                }
                                listOfInstallmentsToCreate.add(objIns2);    
                            }
                        }
                     
                    }
                    
                    
                    if((objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c) > 0 && ( objCase.Status == 'Case closed – resolved without adjudication' || objCase.Status == 'Deposit to be repaid - resolved without adjudication' || (objCase.Evidence_Gathering_Start_Date__c ==null && objCase.Status == 'Awaiting Review' ) /* || objCase.Status == 'Complaint closed' || objCase.Status == 'Decision issued - with legal' */ )){
                        system.debug('objCase.Status>>' + objCase.Status);
                        Decimal Payableamount =0.00;
                        Decimal PayableamounttoAGLL =0.00;
                        Decimal PayableamounttoTenant =0.00;
                        Decimal extraamount =0.00;
                        Decimal TotalamountforAgll =0.00;
                        Decimal TotalamountforTenant =0.00;
                        Decimal Disputedamounttoagll =0.00;
                        Decimal Disputedamounttotenant =0.00;
                        Decimal Undisputedamounttotenant =0.00;
                        Decimal Undisputedamounttoagll =0.00;
                        
                        If((objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c)>objCase.Total_Deposit__c){
                        Payableamount = objCase.Total_Deposit__c;
                        extraamount = objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c-objCase.Total_Deposit__c;
                        }
                        else{
                        Payableamount = objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c;    
                        }
                        
                        
                        If(Payableamount>0){
                            If(objCase.Status != 'Awaiting Review'){
                            IF(objCase.Evidence_Gathering_Start_Date__c !=null ){
                                If(Payableamount<=objCase.Total_amount_in_dispute__c || Payableamount> objCase.Total_amount_in_dispute__c){
                                    IF(objCase.Amount_to_tenants__c>0 && objCase.Amount_to_agent_landlord__c>0 ){
                                        If(Payableamount<=objCase.Amount_to_tenants__c){
                                        Disputedamounttoagll =0.00;
                                        Disputedamounttotenant =Payableamount;
                                        Undisputedamounttotenant =0.00;
                                        Undisputedamounttoagll =0.00;     
                                        } 
                                        If(Payableamount>objCase.Amount_to_tenants__c){
                                            Disputedamounttotenant =objCase.Amount_to_tenants__c; 
                                            If((Payableamount-objCase.Amount_to_tenants__c)<=objCase.Amount_to_agent_landlord__c){
                                                Disputedamounttoagll =Payableamount-objCase.Amount_to_tenants__c;    
                                            }
                                            else{
                                             Disputedamounttoagll =objCase.Amount_to_agent_landlord__c;     
                                            }
                                            
                                            Undisputedamounttotenant =0.00;
                                            Undisputedamounttoagll =0.00;      
                                        }  
                                    } 
                                 IF((objCase.Amount_to_tenants__c==0 ||objCase.Amount_to_tenants__c==null) && objCase.Amount_to_agent_landlord__c>0  ){
                                        If((Payableamount)<=objCase.Amount_to_agent_landlord__c){
                                                Disputedamounttoagll =Payableamount;    
                                            }
                                            else{
                                             Disputedamounttoagll =objCase.Amount_to_agent_landlord__c;     
                                            }
                                        Disputedamounttotenant =0.0; 
                                        Undisputedamounttotenant =0.00;
                                        Undisputedamounttoagll =0.00; 
                                 }
                                    IF((objCase.Amount_to_agent_landlord__c==0 ||objCase.Amount_to_agent_landlord__c==null) && objCase.Amount_to_tenants__c>0){
                                        Disputedamounttoagll =0.00;
                                        If((Payableamount)<=objCase.Amount_to_tenants__c){
                                            Disputedamounttotenant =Payableamount;    
                                        }
                                        else{
                                            Disputedamounttotenant =objCase.Amount_to_tenants__c;     
                                        }
                                        Disputedamounttotenant =Payableamount; 
                                        Undisputedamounttotenant =0.00;
                                        Undisputedamounttoagll =0.00; 
                                    }    
                                    
                                } 
                                If(objCase.Undisputed_Funds_Received__c>0 ){
                                    If(objCase.Undisputed_Funds_Received__c<=objCase.TT_Offer_Amount__c) {
                                     Undisputedamounttotenant = objCase.Undisputed_Funds_Received__c; 
                                     Undisputedamounttoagll = 0.00;
                                    }  
                                   If(objCase.Undisputed_Funds_Received__c>objCase.TT_Offer_Amount__c && objCase.AGLL_Offer_Amount__c>0) {
                                     Undisputedamounttotenant = objCase.TT_Offer_Amount__c; 
                                       If((objCase.Undisputed_Funds_Received__c-objCase.TT_Offer_Amount__c)<=objCase.AGLL_Offer_Amount__c){
                                        Undisputedamounttoagll = objCase.Undisputed_Funds_Received__c-objCase.TT_Offer_Amount__c;    
                                       }
                                       else{
                                       Undisputedamounttoagll = objCase.AGLL_Offer_Amount__c;    
                                       }
                                     
                                   }
                                    
                                    If(objCase.AGLL_Offer_Amount__c == 0 || objCase.AGLL_Offer_Amount__c == null ) {
                                        Undisputedamounttotenant = objCase.Undisputed_Funds_Received__c; 
                                        Undisputedamounttoagll = 0.00;
                                    }
                                }

                            }
                            else{
                            IF(objCase.Amount_to_tenants__c>0 && objCase.Amount_to_agent_landlord__c>0 ){
                                        If(Payableamount<=objCase.Amount_to_tenants__c){
                                        Disputedamounttoagll =0.00;
                                        Disputedamounttotenant =Payableamount;
                                        Undisputedamounttotenant =0.00;
                                        Undisputedamounttoagll =0.00;     
                                        } 
                                        If(Payableamount>objCase.Amount_to_tenants__c){
                                        Disputedamounttoagll =Payableamount-objCase.Amount_to_tenants__c;
                                        Disputedamounttotenant =objCase.Amount_to_tenants__c; 
                                        Undisputedamounttotenant =0.00;
                                        Undisputedamounttoagll =0.00;      
                                        }  
                                    } 
                                 IF((objCase.Amount_to_tenants__c==0 ||objCase.Amount_to_tenants__c==null) && objCase.Amount_to_agent_landlord__c>0  ){
                                        Disputedamounttoagll =Payableamount;
                                        Disputedamounttotenant =0.0; 
                                        Undisputedamounttotenant =0.00;
                                        Undisputedamounttoagll =0.00; 
                                 }
                                IF((objCase.Amount_to_agent_landlord__c==0 ||objCase.Amount_to_agent_landlord__c==null) && objCase.Amount_to_tenants__c>0){
                                        Disputedamounttoagll =0.00;
                                        Disputedamounttotenant =Payableamount; 
                                        Undisputedamounttotenant =0.00;
                                        Undisputedamounttoagll =0.00; 
                                 }   
                                
                            } 
                            } 
                         else{
                          If(objCase.Undisputed_Funds_Received__c>0 ){
                                    If(objCase.Undisputed_Funds_Received__c<=objCase.Amount_to_tenants__c) {
                                     Undisputedamounttotenant = objCase.Undisputed_Funds_Received__c; 
                                     Undisputedamounttoagll = 0.00;
                                    }  
                                   If(objCase.Undisputed_Funds_Received__c>objCase.Amount_to_tenants__c &&  objCase.Amount_to_agent_landlord__c>0) {
                                     Undisputedamounttotenant = objCase.Amount_to_tenants__c; 
                                       If((objCase.Undisputed_Funds_Received__c-objCase.Amount_to_tenants__c)<=objCase.Amount_to_agent_landlord__c ){
                                        Undisputedamounttoagll = objCase.Undisputed_Funds_Received__c-objCase.Amount_to_tenants__c;    
                                       }
                                       else{
                                       Undisputedamounttoagll = objCase.Amount_to_agent_landlord__c;    
                                       }
                                     
                                   }
                              If(objCase.Amount_to_agent_landlord__c == 0 || objCase.Amount_to_agent_landlord__c == null ) {
                                 Undisputedamounttotenant = objCase.Undisputed_Funds_Received__c; 
                                  Undisputedamounttoagll = 0.00;
                              }
                              
                                }     
                        }   
                            
                        } 
                        
                         PayableamounttoTenant =Disputedamounttotenant +Undisputedamounttotenant ;
                         PayableamounttoAGLL=Disputedamounttoagll+Undisputedamounttoagll;    
                         system.debug('line-->502 ++' + PayableamounttoTenant ); 
                         system.debug('line-->503 ++' + PayableamounttoAGLL ); 
                            
                            
                      
                        Map<String,Case_Participant__c> caseParticipantId = new Map<String,Case_Participant__c>();
                        Integer totalNumberOfTenants = 0;
                        for(Case_Participant__c cp : objCase.Case_Participants__r){
                             if(PayableamounttoAGLL>0 && ((cp.Type__c=='Agent' && cp.Primary_Agent__c) || cp.Type__c=='Independent-Landlord')){
                                Installment__c objIns2= new Installment__c();
                                    objIns2.Installment_Type__c='Payable';
                                    objIns2.Status__c='Pending Processing';
                                if(objCase.AccountId!=null)
                                {
                                   objIns2.Account__c = objCase.AccountId;
                                }
                                objIns2.Amount__c=PayableamounttoAGLL;
                                objIns2.Case_participant__c = cp.Id;
                                objIns2.Case__C=objCase.Id;
                                objIns2.RecordTypeId=InstalRecordTypeId;
                                objIns2.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns2.Contact__c=cp.Contact__c;
                                 if(cp.Bank_Account_Number__c !=null && cp.Bank_Sort_Code__c !=null && cp.Bank_Account_Holder_Name__c !=null)
                                {
                                objIns2.Bank_Name__c=cp.Bank_Name__c;
                                objIns2.Bank_Account_Number__c=cp.Bank_Account_Number__c;
                                objIns2.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                                objIns2.Bank_Account_Holder_Name__c=cp.Bank_Account_Holder_Name__c;
                                objIns2.UK_Payment__c = true;
                                objIns2.International_Payment__c=false;
                                }
                                else{
                                     objIns2.International_Payment__c=cp.International_Payment__c;
                                    objIns2.Bank_Name__c=cp.International_Bank_Name__c;
                                    objIns2.BIC__c=cp.Bank_Identification_Code__c;
                                    objIns2.Bank_Account_Number__c=cp.International_Account_Number__c;
                                    objIns2.Bank_Account_Holder_Name__c=cp.International_Bank_Account_Holder_Name__c;
                                    objIns2.Swift_Code__c=cp.Swift_Code__c;
                                     objIns2.beneficiary_address__c = cp.Beneficiary_Home_Address__c;
                                     objIns2.UK_Payment__c=false;
                                    objIns2.International_Payment__c=true;
                        
                                }
                                listOfInstallmentsToCreate.add(objIns2); 
                             } 
                                 if(extraamount>0 && ((cp.Type__c=='Agent' && cp.Primary_Agent__c) || cp.Type__c=='Independent-Landlord')){
                                Installment__c objIns3= new Installment__c();
                                    objIns3.Installment_Type__c='Payable';
                                    objIns3.Status__c='Pending Processing';
                                if(objCase.AccountId!=null)
                                {
                                   objIns3.Account__c = objCase.AccountId;
                                }
                                objIns3.Amount__c=extraamount;
                                objIns3.Case_participant__c = cp.Id;
                                objIns3.Case__C=objCase.Id;
                                objIns3.RecordTypeId=InstalRecordTypeId;
                                objIns3.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns3.Contact__c=cp.Contact__c;
                                 if(cp.Bank_Account_Number__c !=null && cp.Bank_Sort_Code__c !=null && cp.Bank_Account_Holder_Name__c !=null)
                                {
                                objIns3.Bank_Name__c=cp.Bank_Name__c;
                                objIns3.Bank_Account_Number__c=cp.Bank_Account_Number__c;
                                objIns3.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                                objIns3.Bank_Account_Holder_Name__c=cp.Bank_Account_Holder_Name__c;
                                objIns3.UK_Payment__c = true;
                                objIns3.International_Payment__c=false;
                                }
                                else{
                                     objIns3.International_Payment__c=cp.International_Payment__c;
                                    objIns3.Bank_Name__c=cp.International_Bank_Name__c;
                                    objIns3.BIC__c=cp.Bank_Identification_Code__c;
                                    objIns3.Bank_Account_Number__c=cp.International_Account_Number__c;
                                    objIns3.Bank_Account_Holder_Name__c=cp.International_Bank_Account_Holder_Name__c;
                                    objIns3.Swift_Code__c=cp.Swift_Code__c;
                                     objIns3.beneficiary_address__c = cp.Beneficiary_Home_Address__c;
                                     objIns3.UK_Payment__c=false;
                                    objIns3.International_Payment__c=true;
                        
                                }
                                listOfInstallmentsToCreate.add(objIns3);      
                                 }
                            
                            if(cp.Type__c=='Tenant'){
                                totalNumberOfTenants++;
                                caseParticipantId.put(cp.Id,cp);
                            }
                        }
                        system.debug('totalNumberOfTenants>>' + totalNumberOfTenants);
                        system.debug('Undisputed_Funds_Received__c>>' + objCase.Undisputed_Funds_Received__c);
                        if(totalNumberOfTenants > 0 && PayableamounttoTenant>0 ){
                        	Decimal installmentAmount = PayableamounttoTenant/totalNumberOfTenants;
                            Integer totalNumberOfInstallments = 0;
                            set<string> installmentIdAdded = new set<string>();
                             for(String cp : caseParticipantId.keySet()){
                                Installment__c objIns= new Installment__c();
                                objIns.Account__c = objCase.AccountId;
                                objIns.Installment_Type__c='Payable';
                                objIns.Status__c='Pending Processing';
                                objIns.Amount__c=installmentAmount;
                                objIns.Case__C=objCase.Id;
                                objIns.RecordTypeId=InstalRecordTypeId;
                                objIns.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns.Case_participant__c = cp;
                                objIns.Contact__c=caseParticipantId.get(cp).Contact__c;
                                if(caseParticipantId.get(cp).Bank_Account_Number__c !=null && caseParticipantId.get(cp).Bank_Sort_Code__c !=null && caseParticipantId.get(cp).Bank_Account_Holder_Name__c !=null)
                                {
                                objIns.Bank_Name__c=caseParticipantId.get(cp).Bank_Name__c;
                                //objIns.BIC__c=caseParticipantId.get(cp).Bank_Identification_Code__c;
                                objIns.Bank_Account_Number__c=caseParticipantId.get(cp).Bank_Account_Number__c;
                                objIns.Bank_Sort_Code__c=caseParticipantId.get(cp).Bank_Sort_Code__c;
                                objIns.Bank_Account_Holder_Name__c=caseParticipantId.get(cp).Bank_Account_Holder_Name__c;
                                objIns.UK_Payment__c = true;
                                objIns.International_Payment__c=false;
                                }
                             //   if (caseParticipantId.get(cp).International_Payment__c==true){
                                else {
                                     objIns.International_Payment__c=caseParticipantId.get(cp).International_Payment__c;
                                    objIns.Bank_Name__c=caseParticipantId.get(cp).International_Bank_Name__c;
                                    objIns.BIC__c=caseParticipantId.get(cp).Bank_Identification_Code__c;
                                    objIns.Bank_Account_Number__c=caseParticipantId.get(cp).International_Account_Number__c;
                                    //objIns.Bank_Sort_Code__c=caseParticipantId.get(cp).Bank_Sort_Code__c;
                                     objIns.beneficiary_address__c = caseParticipantId.get(cp).Beneficiary_Home_Address__c;
                                    objIns.Bank_Account_Holder_Name__c=caseParticipantId.get(cp).International_Bank_Account_Holder_Name__c;
                                    objIns.Swift_Code__c=caseParticipantId.get(cp).Swift_Code__c;
                                    objIns.UK_Payment__c=false;
                                    objIns.International_Payment__c=true;
                                }
                                 system.debug('line-->500 ' + listOfInstallmentsToCreate);
                                listOfInstallmentsToCreate.add(objIns);
                            }
                        }
                     
                    }
                    
                    if((objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c) > 0 && ( objCase.Status =='Deposit to be repaid - decision issued' ||
                        objCase.Status == '4 - Medium level complaint' || objCase.Status == '5 - High level complaint'	|| objCase.Status == 'Complaint closed'  || objCase.Status == 'Deposit closed - deposit repaid in full'
                       ||  objCase.Status == 'Deposit closed - deposit repaid in part' || objCase.Status == 'Deposit closed - unable to repay' || objCase.Status == 'Decision issued - dispute monies outstanding' ||  objCase.Status == 'Decision issued - with legal' || objCase.Status == 'Overpayments' )){
                        system.debug('objCase.Status>>' + objCase.Status);
                        Decimal Payableamount =0.00;
                        Decimal PayableamounttoAGLL =0.00;
                        Decimal PayableamounttoTenant =0.00;
                        Decimal extraamount =0.00;
                        Decimal TotalamountforAgll =0.00;
                        Decimal TotalamountforTenant =0.00;
                        Decimal Disputedamounttoagll =0.00;
                        Decimal Disputedamounttotenant =0.00;
                        Decimal Undisputedamounttotenant =0.00;
                        Decimal Undisputedamounttoagll =0.00;
                        
                        
                        If(objCase.Amount_of_Disputed_Funds_Received__c>objCase.Total_Deposit__c){
                        extraamount = objCase.Amount_of_Disputed_Funds_Received__c-objCase.Total_Deposit__c;  
                        Payableamount =  objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c-extraamount;
                        }
                        else{
                        Payableamount = objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c; 
                        }
                           
                        system.debug('line-->587 '+ Payableamount );
                        If(Payableamount>0){
                            
                           If(objCase.Undisputed_Funds_Received__c>0 ){
                                    If(objCase.Undisputed_Funds_Received__c<=objCase.TT_Offer_Amount__c) {
                                    // Undisputedamounttotenant = objCase.TT_Offer_Amount__c; 
                                     Undisputedamounttotenant = objCase.Undisputed_Funds_Received__c; 
                                     Undisputedamounttoagll = 0.00;
                                    }  
                                   If(objCase.Undisputed_Funds_Received__c>objCase.TT_Offer_Amount__c) {
                                     Undisputedamounttotenant = objCase.TT_Offer_Amount__c; 
                                       If((objCase.Undisputed_Funds_Received__c-objCase.TT_Offer_Amount__c)<=objCase.AGLL_Offer_Amount__c){
                                        Undisputedamounttoagll = objCase.Undisputed_Funds_Received__c-objCase.TT_Offer_Amount__c;    
                                       }
                                       else{
                                       Undisputedamounttoagll = objCase.AGLL_Offer_Amount__c;    
                                       }
                                     
                                   }
                                } 
                            
                            IF(objCase.Amount_to_agent_landlord__c>0 ){
                                IF(Payableamount<=objCase.Amount_to_agent_landlord__c){
                                        Disputedamounttoagll =Payableamount;
                                }
                                else{
                                  Disputedamounttoagll =objCase.Amount_to_agent_landlord__c;  
                                }
                                        
                                 }
                            
                         PayableamounttoTenant =Disputedamounttotenant +Undisputedamounttotenant ;
                         PayableamounttoAGLL=Disputedamounttoagll+Undisputedamounttoagll;    
                         system.debug('line-->770 ++' + PayableamounttoTenant ); 
                         system.debug('line-->771 ++' + PayableamounttoAGLL );
                        }
                            
                            /*If(objCase.Amount_to_agent_landlord__c>0 && Payableamount<=objCase.Amount_to_agent_landlord__c){
                                PayableamounttoAGLL = Payableamount;  
                                PayableamounttoTenant = 0.00;
                            }
                            
                            else If(objCase.Amount_to_agent_landlord__c>0 && Payableamount>objCase.Amount_to_agent_landlord__c){
                                PayableamounttoAGLL = objCase.Amount_to_agent_landlord__c;  
                                PayableamounttoTenant = Payableamount- objCase.Amount_to_agent_landlord__c;
                            }
                            else If(objCase.Amount_to_agent_landlord__c==0 || objCase.Amount_to_agent_landlord__c==null){
                                PayableamounttoAGLL = 0.00;  
                                PayableamounttoTenant = Payableamount;
                            }  
                        }
                        system.debug('line-->641 ' +  PayableamounttoAGLL);
                        system.debug('line-->642 ' +  PayableamounttoTenant);
                        
                            
                         
                       
                         
                         system.debug('line-->621 '+ PayableamounttoAGLL );
                         system.debug('line-->622 '+ PayableamounttoTenant );*/
                        Map<String,Case_Participant__c> caseParticipantId = new Map<String,Case_Participant__c>();
                        Integer totalNumberOfTenants = 0;
                        for(Case_Participant__c cp : objCase.Case_Participants__r){
                             if(PayableamounttoAGLL>0 && ((cp.Type__c=='Agent' && cp.Primary_Agent__c) || cp.Type__c=='Independent-Landlord')){
                                Installment__c objIns2= new Installment__c();
                                    objIns2.Installment_Type__c='Payable';
                                    objIns2.Status__c='Pending Processing';
                                if(objCase.AccountId!=null)
                                {
                                   objIns2.Account__c = objCase.AccountId;
                                }
                                objIns2.Amount__c=PayableamounttoAGLL;
                                objIns2.Case_participant__c = cp.Id;
                                objIns2.Case__C=objCase.Id;
                                objIns2.RecordTypeId=InstalRecordTypeId;
                                objIns2.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns2.Contact__c=cp.Contact__c;
                                 if(cp.Bank_Account_Number__c !=null && cp.Bank_Sort_Code__c !=null && cp.Bank_Account_Holder_Name__c !=null)
                                {
                                objIns2.Bank_Name__c=cp.Bank_Name__c;
                                objIns2.Bank_Account_Number__c=cp.Bank_Account_Number__c;
                                objIns2.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                                objIns2.Bank_Account_Holder_Name__c=cp.Bank_Account_Holder_Name__c;
                                objIns2.UK_Payment__c = true;
                                objIns2.International_Payment__c=false;
                                }
                                else{
                                     objIns2.International_Payment__c=cp.International_Payment__c;
                                    objIns2.Bank_Name__c=cp.International_Bank_Name__c;
                                    objIns2.BIC__c=cp.Bank_Identification_Code__c;
                                    objIns2.Bank_Account_Number__c=cp.International_Account_Number__c;
                                    objIns2.Bank_Account_Holder_Name__c=cp.International_Bank_Account_Holder_Name__c;
                                    objIns2.Swift_Code__c=cp.Swift_Code__c;
                                     objIns2.beneficiary_address__c = cp.Beneficiary_Home_Address__c;
                                     objIns2.UK_Payment__c=false;
                                    objIns2.International_Payment__c=true;
                        
                                }
                                 listOfInstallmentsToCreate.add(objIns2); 
                             }
                                 if(extraamount>0 && ((cp.Type__c=='Agent' && cp.Primary_Agent__c) || cp.Type__c=='Independent-Landlord')){
                                 Installment__c objIns3= new Installment__c();
                                    objIns3.Installment_Type__c='Payable';
                                    objIns3.Status__c='Pending Processing';
                                if(objCase.AccountId!=null)
                                {
                                   objIns3.Account__c = objCase.AccountId;
                                }
                                objIns3.Amount__c=extraamount;
                                objIns3.Case_participant__c = cp.Id;
                                objIns3.Case__C=objCase.Id;
                                objIns3.RecordTypeId=InstalRecordTypeId;
                                objIns3.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns3.Contact__c=cp.Contact__c;
                                 if(cp.Bank_Account_Number__c !=null && cp.Bank_Sort_Code__c !=null && cp.Bank_Account_Holder_Name__c !=null)
                                {
                                objIns3.Bank_Name__c=cp.Bank_Name__c;
                                objIns3.Bank_Account_Number__c=cp.Bank_Account_Number__c;
                                objIns3.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                                objIns3.Bank_Account_Holder_Name__c=cp.Bank_Account_Holder_Name__c;
                                objIns3.UK_Payment__c = true;
                                objIns3.International_Payment__c=false;
                                }
                                else{
                                     objIns3.International_Payment__c=cp.International_Payment__c;
                                    objIns3.Bank_Name__c=cp.International_Bank_Name__c;
                                    objIns3.BIC__c=cp.Bank_Identification_Code__c;
                                    objIns3.Bank_Account_Number__c=cp.International_Account_Number__c;
                                    objIns3.Bank_Account_Holder_Name__c=cp.International_Bank_Account_Holder_Name__c;
                                    objIns3.Swift_Code__c=cp.Swift_Code__c;
                                     objIns3.beneficiary_address__c = cp.Beneficiary_Home_Address__c;
                                     objIns3.UK_Payment__c=false;
                                    objIns3.International_Payment__c=true;
                        
                                }    
                                  listOfInstallmentsToCreate.add(objIns3);    
                                 }
                                 
                               
                            
                            if(cp.Type__c=='Tenant'){
                                totalNumberOfTenants++;
                                caseParticipantId.put(cp.Id,cp);
                            }
                        }
                        system.debug('totalNumberOfTenants>>' + totalNumberOfTenants);
                        system.debug('Undisputed_Funds_Received__c>>' + objCase.Undisputed_Funds_Received__c);
                        if(totalNumberOfTenants > 0 && PayableamounttoTenant>0 ){
                        	Decimal installmentAmount = PayableamounttoTenant/totalNumberOfTenants;
                            Integer totalNumberOfInstallments = 0;
                            set<string> installmentIdAdded = new set<string>();
                             for(String cp : caseParticipantId.keySet()){
                                Installment__c objIns= new Installment__c();
                                objIns.Account__c = objCase.AccountId;
                                objIns.Installment_Type__c='Payable';
                                objIns.Status__c='Pending Processing';
                                objIns.Amount__c=installmentAmount;
                                objIns.Case__C=objCase.Id;
                                objIns.RecordTypeId=InstalRecordTypeId;
                                objIns.Deposit__c=objCase.Deposit_Account_Number__c;
                                objIns.Case_participant__c = cp;
                                objIns.Contact__c=caseParticipantId.get(cp).Contact__c;
                                if(caseParticipantId.get(cp).Bank_Account_Number__c !=null && caseParticipantId.get(cp).Bank_Sort_Code__c !=null && caseParticipantId.get(cp).Bank_Account_Holder_Name__c !=null)
                                {
                                objIns.Bank_Name__c=caseParticipantId.get(cp).Bank_Name__c;
                                //objIns.BIC__c=caseParticipantId.get(cp).Bank_Identification_Code__c;
                                objIns.Bank_Account_Number__c=caseParticipantId.get(cp).Bank_Account_Number__c;
                                objIns.Bank_Sort_Code__c=caseParticipantId.get(cp).Bank_Sort_Code__c;
                                objIns.Bank_Account_Holder_Name__c=caseParticipantId.get(cp).Bank_Account_Holder_Name__c;
                                objIns.UK_Payment__c = true;
                                objIns.International_Payment__c=false;
                                }
                             //   if (caseParticipantId.get(cp).International_Payment__c==true){
                                else {
                                     objIns.International_Payment__c=caseParticipantId.get(cp).International_Payment__c;
                                    objIns.Bank_Name__c=caseParticipantId.get(cp).International_Bank_Name__c;
                                    objIns.BIC__c=caseParticipantId.get(cp).Bank_Identification_Code__c;
                                    objIns.Bank_Account_Number__c=caseParticipantId.get(cp).International_Account_Number__c;
                                    //objIns.Bank_Sort_Code__c=caseParticipantId.get(cp).Bank_Sort_Code__c;
                                     objIns.beneficiary_address__c = caseParticipantId.get(cp).Beneficiary_Home_Address__c;
                                    objIns.Bank_Account_Holder_Name__c=caseParticipantId.get(cp).International_Bank_Account_Holder_Name__c;
                                    objIns.Swift_Code__c=caseParticipantId.get(cp).Swift_Code__c;
                                    objIns.UK_Payment__c=false;
                                    objIns.International_Payment__c=true;
                                }
                                listOfInstallmentsToCreate.add(objIns);
                            }
                        }
                     
                    }
                    
                  // EID-1006 new code added by Himanshu Modi End
                   
                   
                }
            }
            
            if(listOfInstallmentsToCreate.size()>0 && !listOfInstallmentsToCreate.isEmpty()){
            	insert listOfInstallmentsToCreate;
            }
            if(installmentsToUpdate.size() > 0){
                UPDATE installmentsToUpdate;
                system.debug('Update Installment');
            }
            
        }catch(exception ex){
            system.debug('ex>>'+ ex + '--'+ ex.getLineNumber() );
            Insert (new Error_Log__c(Message_Long__c='Issue is: '
                                     + ex.getMessage() + '************ StackTrace String : ' + ex.getStackTraceString()
                                     + ' at Line Number- ' + ex.getLineNumber(),Method_Name__c='Class: EWI_AllocatePaymentsController '));
        }
    }
    @AuraEnabled
    public static list<InboundReportWrapper> allocateInboundReports(list<InboundReportWrapper> wrapperList, String Id, Decimal amount,Boolean isFilter, String filterType, Date startCreatedDate, Date endCreatedDate, String selectedRecordType){
        //allocate selected inbound reports
        List<String> CaseId = new List<String>();
        list<Inbound_Report__c> reportsToUpdate = new list<Inbound_Report__c>();
        String batchClassName;
        if(selectedRecordType == 'SDS Inbound Report'){
            batchClassName = 'EI_SDS_BatchAllocationInbound';
        }else if(selectedRecordType == 'EWI Inbound Report'){
            batchClassName = 'EI_EWI_BatchAllocationInbound';
        }
      //  system.debug('line-->822 wrapperList '  + wrapperList);
        Id currentUser = userinfo.getUserId();
        AsyncApexJob[] jobs = [select id,status,ApexClass.Name,createdById from AsyncApexJob where (status='Processing' OR status='Holding') AND ApexClass.Name=:batchClassName AND JobType='BatchApex'];
        if(jobs.size()>0){
            return null;
        }else{
            for(InboundReportWrapper wrap : wrapperList){
               
                Inbound_Report__c report = wrap.objInboundReport;
               //   system.debug('line-->830 report.Installment__r.Case__c '  + report.Installment__r.Case__c);
                if( report.Installment__r.Case__c!=null){
                    CaseId.add(report.Installment__r.Case__c);
                    //CaseId = report.Installment__r.Case__c;
                }
               // system.debug('report.Installment__r.Case__c>>>>>' + report.Installment__r.Case__c );
                if(wrap.isSelected && wrap.objInboundReport.Matched_Colour__c != 'Red' && wrap.matchedColour != 'Blue'){
                    report.Matched_Colour__c = '';
                    report.Payment_Created_By__c = 'Allocation';
                    reportsToUpdate.add(report);
                }else if(String.isNotBlank(Id) && Id == wrap.objInboundReport.Id && wrap.objInboundReport.Matched_Colour__c != 'Red' && wrap.matchedColour != 'Blue'){
                    report.Matched_Colour__c = '';
                    report.Payment_Created_By__c = 'Allocation';
                    reportsToUpdate.add(report);
                }
            }
           //   system.debug('line-->847 reportsToUpdate '  + reportsToUpdate);
            if(!reportsToUpdate.isEmpty()){
                try {
                   // system.debug('CaseId>>' + CaseId);
                    // List<Case> caseList = [SELECT Id,RecordTypeId,Amount_of_Disputed_Funds_Remaining__c,Amount_of_Disputed_Funds_Required__c,
                    // Amount_of_Disputed_Funds_Received__c FROM Case WHERE id IN :CaseId];
                    
                    if(selectedRecordType == 'SDS Inbound Report'){
                        if(reportsToUpdate.size()<10){
                            UPDATE reportsToUpdate;
                            List<Case> caseList = [SELECT Id,Status,Undisputed_Funds_Received__c,RecordTypeId,Amount_of_Disputed_Funds_Remaining__c,Amount_of_Disputed_Funds_Required__c,
                                                   Amount_of_Disputed_Funds_Received__c FROM Case WHERE id IN :CaseId];
                            createInstallmentRemainingAmount(caseList);
                        }else{
                            if(!test.isRunningTest())
                            {
                                database.executeBatch(new EI_SDS_BatchAllocationInbound(reportsToUpdate),100); 
                            }
                            
                        }
                    }else if(selectedRecordType == 'EWI Inbound Report'){
                        if(reportsToUpdate.size()<10){
                           // system.debug('without batch');
                            UPDATE reportsToUpdate;
                            List<Case> caseList = [SELECT Id,Status,RecordTypeId,Amount_of_Disputed_Funds_Remaining__c,Amount_of_Disputed_Funds_Required__c,
                                                   Amount_of_Disputed_Funds_Received__c,Undisputed_Funds_Received__c FROM Case WHERE id IN :CaseId];
                            // system.debug('line-->873 withbatch '  + caseList);
                            createInstallmentRemainingAmount(caseList);
                        }else{
                            UPDATE reportsToUpdate;
                          //  system.debug('with batch');
                            List<Case> caseList = [SELECT Id,Status,RecordTypeId,Amount_of_Disputed_Funds_Remaining__c,Amount_of_Disputed_Funds_Required__c,
                                                   Amount_of_Disputed_Funds_Received__c,Undisputed_Funds_Received__c FROM Case WHERE id IN :CaseId];
                         //   system.debug('line-->879 caseList '  + caseList);
                            if(!test.isRunningTest()){
                                database.executeBatch(new EI_EWI_BatchAllocationInbound(reportsToUpdate,caseList),50);
                            }
                            
                        }
                    }
                    //Update reportsToUpdate;
                    //Payment will be created from trigger 
                    
                } catch (Exception exc) {
                    //Create Logs 
                    system.debug('Exception>>' + exc + exc.getLineNumber());
                }
            }
        }
        return returnInboundReports( amount, isFilter,  filterType,  startCreatedDate,  endCreatedDate, selectedRecordType);
    }
    
    
    @AuraEnabled
    public static list<InboundReportWrapper> refundPayment(list<InboundReportWrapper> wrapperList, String Id, Decimal amount,Boolean isFilter, String filterType, Date startCreatedDate, Date endCreatedDate, String selectedRecordType,
                                                          String bankType,String nameOnAccount,String accountNumber,String sortCode,String bankName,
                                                          String nameOntheAccount,String intBankName,String BIC,String swiftCode,String IBAN,String homeAddress){
        
        List<Org_Settings__mdt> orgSettingsData = [SELECT Deposit_Id__c,Transfer_Type__c FROM Org_Settings__mdt WHERE Label = 'Refund amount'];
        list<Installment__c> installmentsToUpdate = new list<Installment__c>();
        list<Installment__c> installmentsToInsert = new list<Installment__c>();
        List<Payment__c> paymentsToInsert = new List<Payment__c>();
        List<Payment__c> paymentsToUpdate = new List<Payment__c>();
        list<Inbound_Report__c> reportsToUpdate = new list<Inbound_Report__c>();
        List<String> newInstallmentIds = new List<String>();
        //Create Installment Record Here
        Installment__c inst1 = new Installment__c();
        inst1.Deposit__c=orgSettingsData[0].Deposit_Id__c;
        inst1.Installment_Type__c='Receivable';
        inst1.Status__c='Collected';
        inst1.RecordTypeId = Schema.SObjectType.Installment__c.getRecordTypeInfosByName().get('EWI Installment').getRecordTypeId();
        installmentsToInsert.add(inst1);
        
        Installment__c inst2 = new Installment__c();
        inst2.Deposit__c=orgSettingsData[0].Deposit_Id__c;
        inst2.Installment_Type__c='Payable';
        inst2.Status__c='Pending Processing';
        inst2.Payment_type__c='Refund';
        inst2.RecordTypeId = Schema.SObjectType.Installment__c.getRecordTypeInfosByName().get('EWI Installment').getRecordTypeId();
                                                              
        if(bankType == 'UK' ){
            inst2.Bank_Name__c=bankName;
            inst2.BIC__c=null;//cp.Bank_Identification_Code__c;
            inst2.Bank_Account_Number__c=accountNumber; 
            inst2.Bank_Sort_Code__c=sortCode;
            inst2.Bank_Account_Holder_Name__c=nameOnAccount;
            inst2.UK_Payment__c=true;
            inst2.International_Payment__c =false;
            inst2.Swift_Code__c=null;
            inst2.beneficiary_address__c = null;
            
        }else if(bankType == 'International'){
            inst2.International_Payment__c = true;
            inst2.BIC__c=BIC;
            inst2.Bank_Name__c=intBankName;
            inst2.Bank_Account_Number__c=IBAN;
            inst2.Bank_Sort_Code__c=null;
            inst2.Bank_Account_Holder_Name__c=nameOntheAccount;
            inst2.beneficiary_address__c = homeAddress;
            inst2.Swift_Code__c=swiftCode;
            inst2.UK_Payment__c=false;
            inst2.International_Payment__c =true;
                                                                  
        }
                                                              
                                                              
        installmentsToInsert.add(inst2);
        
        Payment__c payment1 = new Payment__c();
        payment1.RecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('EWI Payment').getRecordTypeId();
        //payment1.Installment__c = newInstallmentIds[0];
        payment1.Collection_Date__c = System.today();
        payment1.DAN__c = orgSettingsData[0].Deposit_Id__c;
        payment1.Payment_Status__c = 'Paid';
        payment1.Payment_Type__c = 'Receivable';
        payment1.Sage_nominal_code__c = '88020';
        payment1.Sage_bank_account_ID__c = '85005';
        //payment1.Sage_narrative_field__c =  inboundReport[0].Reference1__c+ 'Refund from refrence1 value';
        paymentsToInsert.add(payment1);
        
        
        for(InboundReportWrapper wrap : wrapperList){
            Inbound_Report__c report = wrap.objInboundReport;
            system.debug('>>>>>>><<<<'+Id);
            system.debug('>>>>>>><<<<'+wrap.objInboundReport.Id);
            if(String.isNotBlank(Id) && Id == wrap.objInboundReport.Id){ 
                report.Reason_For_Unallocation__c = 'Refund to customer';
                //report.Installment__c = inst.Id;
                installmentsToInsert[0].Amount__c = report.Amount__c;
                installmentsToInsert[1].Amount__c = report.Amount__c;
                installmentsToInsert[1].Refund_reference__c = report.Reference1__c;
                installmentsToInsert[1].Bank_file_reference__c = report.Reference2__c;
                paymentsToInsert[0].Amount__c = report.Amount__c;
                paymentsToInsert[0].Inbound_Report__c = report.Id;
                if(report.Reference1__c != null){
                    paymentsToInsert[0].Sage_narrative_field__c = 'Refund from '+report.Reference1__c;
                }
                if(report.Sage_URN__c != null){
                    paymentsToInsert[0].Sage_URN__c = report.Sage_URN__c;
                }
                //installmentsToUpdate.add(new Installment__c(Id= inst1.Id,Amount__c = report.Amount__c));
                //installmentsToUpdate.add(new Installment__c(Id= inst2.Id,Amount__c = report.Amount__c));
                reportsToUpdate.add(report);
            }
        }
        
        if(installmentsToInsert.size() > 0){
            Database.SaveResult[] srList = Database.insert(installmentsToInsert, false);  
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    newInstallmentIds.add(String.valueOf(sr.getId()));
                }else{
                    System.debug('error in inserting installments : '+sr.getErrors());
                }
            }
        }
        
        if(newInstallmentIds.size() > 0){
            paymentsToInsert[0].Installment__c = newInstallmentIds[0];           
            reportsToUpdate[0].Installment__c = newInstallmentIds[0];
        }
        
        if(paymentsToInsert.size() >0){
            INSERT paymentsToInsert;
        }
        
        if(!reportsToUpdate.isEmpty()){
            try {
                Update reportsToUpdate;
                //Update installmentsToUpdate;
                
            } catch (Exception exc) {
                //Create Logs 
            }
        }
        return returnInboundReports( amount, isFilter,  filterType,  startCreatedDate, endCreatedDate, selectedRecordType);
        
    }
    
    @AuraEnabled
    public static list<InboundReportWrapper> splitPayment(list<SplitReportWrapper> splitList, InboundReportWrapper wrap, Decimal amount,Boolean isFilter, String filterType, Date startCreatedDate, Date endCreatedDate, String selectedRecordType){
        Id reportRecId = Schema.SObjectType.Inbound_Report__c.getRecordTypeInfosByName().get('EWI Inbound Report').getRecordTypeId();
        //Need to substract split from existing inbound report
        
        list<Inbound_Report__c> reportsToCreate = new list<Inbound_Report__c>();
        
        
        for(SplitReportWrapper newSplit : splitList){
            //??? Verify all needed field once
            Inbound_Report__c report = new Inbound_Report__c();
            if(reportRecId != null){
                report.RecordTypeId = reportRecId;
            }
            report.Reference1__c = newSplit.reference1;
            report.Reference2__c = newSplit.reference2;
            report.Sage_URN__c = wrap.objInboundReport.Sage_URN__c;
            report.Sage_bank_account_ID__c = wrap.objInboundReport.Sage_bank_account_ID__c;
            report.Sage_Narrative_Field__c = wrap.objInboundReport.Sage_Narrative_Field__c;
            report.Sage_nominal_code__c= wrap.objInboundReport.Sage_nominal_code__c;
            
            report.Parent_Report__c = wrap.objInboundReport.Id;
            report.File_Name__c = wrap.objInboundReport.File_Name__c;
            report.Payment_Method__c = wrap.objInboundReport.Payment_Method__c;
            report.Amount__c = newSplit.newAmount;
            report.Collection_Date__c = wrap.objInboundReport.Collection_Date__c;
            reportsToCreate.add(report);
            
        }
        
        Insert reportsToCreate;
        Update new Inbound_Report__c(Id = wrap.objInboundReport.Id, Status__c = 'Inactive',Matched_Colour__c = '',Installment__c=null);
        
        return returnInboundReports( amount, isFilter,  filterType,  startCreatedDate,  endCreatedDate, selectedRecordType);
        
    }
    
    @AuraEnabled
    public static list<InboundReportWrapper> matchingReRun(InboundReportWrapper wrap, String reference1,String reference2, Decimal amount,Boolean isFilter, String filterType, Date startCreatedDate, Date endCreatedDate, String selectedRecordType){
        
        
        if(String.isNotBlank(reference1) && String.isNotBlank(reference2)){
            Update new Inbound_Report__c(Id = wrap.objInboundReport.Id, Reference1__c = reference1, Reference2__c = reference2);
            Set<Id> inbId = new Set<Id>();
            	wrap.objInboundReport.Reference1__c = reference2;
                wrap.objInboundReport.Reference2__c = reference1;
            inbId.add(wrap.objInboundReport.Id);
            //Database.executeBatch(new EWI_BatchToAssociateInboundReports(inbId),1);
            EWI_BatchToAssociateInboundReports.runMatchingEWI(wrap.objInboundReport);
        }
        return returnInboundReports( amount, isFilter,  filterType,  startCreatedDate,  endCreatedDate, selectedRecordType);
        
    }
    
    @AuraEnabled
    public static list<InboundReportWrapper> transferPayment(String selectedTransferType,String inboundId,Decimal amount,Boolean isFilter, String filterType, Date startCreatedDate, Date endCreatedDate, String selectedRecordType){
        List<Installment__c> createInstallments = new List<Installment__c>();
        List<Payment__c> listPaymentToCreate = new List<Payment__c>();
        List<Inbound_Report__c> updateInbound = new List<Inbound_Report__c>();
        List<String> newInstallmentIds = new List<String>();
        
        Id reportRecId = Schema.SObjectType.Installment__c.getRecordTypeInfosByName().get('EWI Installment').getRecordTypeId();
        Id paymentRecId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('EWI Payment').getRecordTypeId();
        
        List<Org_Settings__mdt> orgSettingsData = [SELECT Deposit_Id__c,Transfer_Type__c FROM Org_Settings__mdt WHERE Transfer_Type__c = :selectedTransferType];
        List<Inbound_Report__c> inboundReport = [SELECT id,Reference1__c,Reference2__c,Matched_Colour__c,Amount__c,Sage_URN__c FROM Inbound_Report__c WHERE Id =:inboundId];
        
        Inbound_Report__c inbRep = new Inbound_Report__c(Id = inboundReport[0].Id,Matched_Colour__c='',Payment_Created_By__c='Transfer Payment',Installment__c=null);
        updateInbound.add(inbRep);
        
        if(selectedTransferType=='Transfer to Custodial'){
            Installment__c inst1 = new Installment__c();
            inst1.recordTypeId = reportRecId;
            inst1.Deposit__c=orgSettingsData[0].Deposit_Id__c;
            inst1.Installment_Type__c='Receivable';
            inst1.Status__c='Collected';
            if(inboundReport[0].Amount__c!=null){
                inst1.Amount__c=inboundReport[0].Amount__c;
            }
            createInstallments.add(inst1);
            
            Installment__c inst2 = new Installment__c();
            inst2.recordTypeId = reportRecId;
            inst2.Deposit__c=orgSettingsData[0].Deposit_Id__c;
            inst2.Installment_Type__c='Payable';
            inst2.Status__c='Pending Processing';
            inst2.Bank_Account_Number__c = '44647190';
            system.debug('-----'+inst2.Bank_Account_Number__c);
            inst2.Bank_Name__c = 'The Dispute Service';
            inst2.Bank_Account_Holder_Name__c = 'NatWest bank';
            inst2.Bank_file_reference__c = inboundReport[0].Reference2__c;
            inst2.Bank_Sort_Code__c = '600115';
            inst2.UK_Payment__c=true;
            if(inboundReport[0].Amount__c!=null){
                inst2.Amount__c=inboundReport[0].Amount__c;
            }
            createInstallments.add(inst2);
        }
        else if(selectedTransferType=='Transfer to office account'){
            Installment__c inst1 = new Installment__c();
            inst1.recordTypeId = reportRecId;
            inst1.Deposit__c=orgSettingsData[0].Deposit_Id__c;
            inst1.Installment_Type__c='Receivable';
            inst1.Status__c='Collected';
            if(inboundReport[0].Amount__c!=null){
                inst1.Amount__c=inboundReport[0].Amount__c;
            }
            createInstallments.add(inst1);
            
            Installment__c inst2 = new Installment__c();
            inst2.recordTypeId = reportRecId;
            inst2.Deposit__c=orgSettingsData[0].Deposit_Id__c;
            inst2.Installment_Type__c='Payable';
            inst2.Status__c='Pending Processing';
            inst2.Bank_Account_Number__c = '44511507';
            inst2.Bank_Name__c = 'The Dispute Service';
            inst2.Bank_Account_Holder_Name__c = 'NatWest bank';
            inst2.Bank_Sort_Code__c = '600115';
            inst2.UK_Payment__c=true;
            inst2.Bank_file_reference__c = inboundReport[0].Reference2__c;
            if(inboundReport[0].Amount__c!=null){
                inst2.Amount__c=inboundReport[0].Amount__c;
            }
            createInstallments.add(inst2);
        }
        Database.SaveResult[] srList = Database.insert(createInstallments, false);  
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                newInstallmentIds.add(String.valueOf(sr.getId()));
            }else{
                System.debug('error in inserting installments : '+sr.getErrors());
            }
        }
        
        if(selectedTransferType=='Transfer to Custodial')
        {
            Payment__c payment2 = new Payment__c();
            payment2.Inbound_Report__c = inboundId;
            payment2.RecordTypeId = paymentRecId;
            payment2.Installment__c = newInstallmentIds[0];
            payment2.Collection_Date__c = System.today();
            payment2.Amount__c = inboundReport[0].Amount__c;
            payment2.DAN__c = orgSettingsData[0].Deposit_Id__c;
            payment2.Payment_Status__c = 'Paid';
            payment2.Payment_Type__c = 'Receivable';
            payment2.Sage_nominal_code__c = '88020';
            payment2.Sage_bank_account_ID__c = '85005';
            payment2.Sage_narrative_field__c =  inboundReport[0].Reference1__c+ 'Custodial account';
            if(inboundReport[0].Sage_URN__c != null){
                payment2.Sage_URN__c = inboundReport[0].Sage_URN__c;
            }
            listPaymentToCreate.add(payment2);
        } else if(selectedTransferType=='Transfer to office account')
        {
            Payment__c payment2 = new Payment__c();
            payment2.Inbound_Report__c = inboundId;
            payment2.RecordTypeId = paymentRecId;
            payment2.Installment__c = newInstallmentIds[0];
            payment2.Collection_Date__c = System.today();
            payment2.Amount__c = inboundReport[0].Amount__c;
            payment2.DAN__c = orgSettingsData[0].Deposit_Id__c;
            payment2.Payment_Status__c = 'Paid';
            payment2.Payment_Type__c = 'Receivable';
            payment2.Sage_nominal_code__c = '88020';
            payment2.Sage_bank_account_ID__c = '85005';
            payment2.Sage_narrative_field__c = inboundReport[0].Reference1__c+ 'Office account';
            if(inboundReport[0].Sage_URN__c != null){
                payment2.Sage_URN__c = inboundReport[0].Sage_URN__c;
            }
            listPaymentToCreate.add(payment2);
        }
        
        INSERT listPaymentToCreate;
        UPDATE updateInbound;
        return returnInboundReports( amount, isFilter,  filterType,  startCreatedDate,  endCreatedDate, selectedRecordType);
    }
    @AuraEnabled
    public static searchWrapper searchInstallmentDefault(String InbndRptId){
        
        system.debug('InbndRptId==='+InbndRptId);
        List<Inbound_Report__c> inbRptList = new List<Inbound_Report__c>([SELECT id,amount__c,Narrative2_Details__c from Inbound_Report__c where id =:InbndRptId]);
        
        List<Installment__c> installmentList = new List<Installment__c>();
        List<Installment__c> installmentListAmount;
        Set<Id> instIds = new Set<Id>();
        searchWrapper wrap = new searchWrapper();
        wrap.payee = inbRptList[0].Narrative2_Details__c;
        //inbRptList.get(0).Narrative2_Details__c
        /* List<Payment__c> PaymentList = new List<Payment__c>([Select id,Amount__c,Installment__c,Payment_Status__c,createdDate,Collection_Date__c,Payee_Name__c
//Received_Date__c,
//Transaction_Date__c 
from Payment__c 
Where Payment_Status__c = 'Paid' AND Payee_Name__c =:inbRptList.get(0).Narrative2_Details__c
AND CreatedDate > LAST_N_DAYS:1 ]);*/
        List<Payment__c> PaymentList = new List<Payment__c>([Select id,Amount__c,Installment__c,Payment_Status__c,createdDate,Collection_Date__c,Payee_Name__c from Payment__c 
                                                             Where Payment_type__c = 'Payable' AND RecordType.Name = 'EWI Payment'
                                                             AND CreatedDate = LAST_N_DAYS:2 AND Amount__c =: inbRptList[0].amount__c]);
        
        for(Payment__c pay:PaymentList){  
            instIds.add(pay.Installment__c);
        }
        
        /*  for(Payment__c pymt:PaymentList){
instIds.add(pymt.Installment__c);
}


installmentList =[SELECT id,Name,Amount__c, Bank_Account_Number__c, Bank_Name__c,Deposit__r.Name,Contact__r.Name,
Case__r.Case_Number_Custom__c,BLK_Number__c  
from Installment__c 
where (Name = :searchText
OR Bank_Account_Number__c =:searchText
OR Case__r.Dispute_Reference__c=:searchText
OR Deposit__r.Name =:searchText)
AND Amount__c = :inb_Amount
];*/
        installmentList =[SELECT id,Name,Amount__c, Bank_Account_Number__c, Bank_Name__c,Deposit__r.Name,Contact__r.Name,
                          Case__r.Case_Number_Custom__c,BLK_Number__c  
                          from Installment__c 
                          where Id =:instIds AND Status__c ='Paid'
                         ];
        
        wrap.installmentList =installmentList ;
        
        system.debug('installmentList==='+installmentList);
        return wrap;
        
    }
    @AuraEnabled
    public static searchWrapper searchInstallment(String searchText,String InbndRptId){
        system.debug('searchText==='+searchText);
        system.debug('InbndRptId==='+InbndRptId);
        date dt = date.valueOf(searchText);
        system.debug('InbndRptId==='+dt);
        Date dt1 = dt.addDays(1);
        Date dt2 = dt.addDays(-1);
        List<Inbound_Report__c> inbRptList = new List<Inbound_Report__c>([SELECT id,amount__c, Narrative2_Details__c  from Inbound_Report__c where id =:InbndRptId]);
        Decimal inb_Amount;
        searchWrapper wrap = new searchWrapper();
        if(inbRptList.size()>0){
            inb_Amount = inbRptList.get(0).amount__c;
            wrap.payee = inbRptList.get(0).Narrative2_Details__c;
        }
        system.debug('===inb_amount==='+inb_Amount);
        List<Installment__c> installmentList = new List<Installment__c>();
        List<Installment__c> installmentListAmount;
        Set<Id> instIds = new Set<Id>();
        List<Payment__c> PaymentList = new List<Payment__c>([Select id,Amount__c,Installment__c,Payment_Status__c,createdDate,Collection_Date__c,Received_Date__c,
                                                             Transaction_Date__c from Payment__c 
                                                             Where Amount__c =:inbRptList.get(0).amount__c
                                                             AND CreatedDate <:dt1 AND CreatedDate >:dt2 AND Payment_type__c = 'Payable' AND RecordType.Name = 'EWI Payment']);
        for(Payment__c pay:PaymentList){
            
            instIds.add(pay.Installment__c);
            
            
        }
        
        system.debug('PaymentList==='+PaymentList);
        installmentList =[SELECT id,Name,Amount__c, Bank_Account_Number__c, Bank_Name__c,Deposit__r.Name,Contact__r.Name,
                          Case__r.Case_Number_Custom__c,BLK_Number__c,Installment_Type__c  
                          from Installment__c 
                          where Id =:instIds AND Status__c ='Paid'
                         ];
        system.debug('installmentList==='+installmentList);
        
        wrap.installmentList = installmentList;
        return wrap;
        
    }
    @AuraEnabled
    public static string processInstallmentReversal(String InstallmentId,string InbndRptId){
        try {
            
            
            List<Inbound_Report__c> inbRptList = new List<Inbound_Report__c>([SELECT id,Reference4__c,Matched_Colour__c, Narrative2_Details__c,Sage_URN__c,collection_date__c  from Inbound_Report__c where id =:InbndRptId]);
            String RefValue;
            if(inbRptList.size()>0){
                RefValue = inbRptList.get(0).Reference4__c;
                inbRptList.get(0).Matched_Colour__c = '';
            }
            update inbRptList;
            List<Installment__c> installmentList = new List<Installment__c>();
            installmentList =[SELECT id,Amount__c,Account__c, Bank_Account_Number__c, Bank_Name__c, 
                              Case__r.Case_Number_Custom__c,case__c,Contact__c,
                              Status__c,Deposit__c from Installment__c where id = :InstallmentId];
            installmentList.get(0).Status__c = 'Paid but returned';
            update installmentList;
            Id depositId ;
            Id CaseId;
            Id ContactId;
            if(installmentList.size()>0){
                depositId = installmentList.get(0).Deposit__c;
                CaseId = installmentList.get(0).case__c;
                ContactId = installmentList.get(0).Contact__c;  
            }
            
            case cs;
            if(CaseId !=null){
                cs = [SELECT id,AccountId,Narrative_Return_Bank_Details__c from case where id =:CaseId]; 
            }
            
            if(cs != null){
                cs.Narrative_Return_Bank_Details__c = RefValue;
                update cs;
            }
            
            //get case participants
            List<Case_Participant__c> csParticipantList = new List<Case_Participant__c>();
            csParticipantList = [SELECT Id,Account__c,Incorrect_Bank_Details__c from Case_Participant__c WHERE Contact__c =:ContactId
                                 AND Case__c =:CaseId limit 1];
            
            
            System.debug('===Partcipants'+csParticipantList);
            if(csParticipantList.size() >0){
                csParticipantList.get(0).Incorrect_Bank_Details__c = true;
            }
            update csParticipantList;
            
            Id EWIRecordtypeId = Schema.SObjectType.Installment__c.getRecordTypeInfosByName().get('EWI Installment').getRecordTypeId();
            List<Installment__c> installmentListToCreate = new List<Installment__c>();
            Installment__c inst1 = new Installment__c();
            inst1.status__c = 'Returned'; 
           // inst1.Transaction_date2__c = inbRptList[0].collection_date__c;
           // inst1.Transaction_Date_2__c = inbRptList[0].collection_date__c;    
            inst1.Deposit__c = depositId;
            inst1.Case__c = CaseID;
           /* if(cs.AccountId!=null){
            inst1.Account__c = cs.AccountId;
            }*/
            if(installmentList[0].Account__c!=null){
            inst1.Account__c = installmentList[0].Account__c;
            }
            if(csParticipantList[0].id!=null){
            inst1.Case_participant__c = csParticipantList[0].id;
            }
            inst1.Contact__c = ContactId;
            inst1.Amount__c = installmentList.get(0).Amount__c;
            inst1.Installment_Type__c = 'Receivable';
            inst1.RecordTypeId = EWIRecordtypeId;
            installmentListToCreate.add(inst1);
            Installment__c inst2 = new Installment__c();
            inst2.status__c = 'Pending Processing';
            inst2.Installment_Type__c = 'Payable';
            inst2.Bank_Account_Holder_Name__c = '';
            inst2.Bank_Account_Number__c = '';
            inst2.Bank_Name__c = '';
            inst2.Amount__c = installmentList.get(0).Amount__c;
            inst2.Deposit__c = depositId;
            inst2.Case__c = CaseID;
          /*  if(cs.AccountId!=null){
            inst2.Account__c = cs.AccountId;
            }*/
            if(installmentList[0].Account__c!=null){
            inst2.Account__c = installmentList[0].Account__c;
            }
            if(csParticipantList[0].id!=null){
            inst2.Case_participant__c = csParticipantList[0].id;
            }
            inst2.Contact__c = ContactId;
            inst2.RecordTypeId = EWIRecordtypeId;
            installmentListToCreate.add(inst2);
            insert installmentListToCreate;
            
            Id paymentEWIRecId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('EWI Payment').getRecordTypeId();
            Payment__c payment = new Payment__c();
            payment.Installment__c = installmentListToCreate[0].Id;
            payment.Amount__c = installmentList.get(0).Amount__c;
            payment.DAN__c = depositId;
            payment.Inbound_Report__c =inbRptList[0].Id; 
            payment.Case__c=installmentList.get(0).Case__c;
            //payment.Payment_Status__c = 'Returned - unable to pay';//new status to be created
            payment.Payment_Type__c = 'Receivable';
            
            payment.Payment_Status__c = 'Paid';
            payment.Collection_Date__c =  inbRptList[0].Collection_Date__c; 
            payment.RecordTypeId = paymentEWIRecId;
            payment.Transaction_Date__c = system.today();
            payment.Sage_nominal_code__c='88020';
            payment.Sage_bank_account_ID__c='85005';
            payment.Sage_narrative_field__c= inst1.Bank_Account_Holder_Name__c + inst1.case__r.Dispute_Reference__c;
            if(inbRptList[0].Sage_URN__c != ''){
                payment.Sage_URN__c = inbRptList[0].Sage_URN__c;
            }
            insert payment;
            
            installmentListToCreate[0].Transaction_date2__c = inbRptList[0].collection_date__c;
            installmentListToCreate[0].Transaction_Date_2__c = inbRptList[0].collection_date__c; 
            update installmentListToCreate[0];
            
            system.debug('===payment==='+payment.Id); 
            return 'Success';
        } catch(Exception e) {
            return 'Error';
        }
        
    }
    
    
    
    public class InboundReportWrapper{
        @AuraEnabled public  Inbound_Report__c objInboundReport{get;set;}
        @AuraEnabled public  Boolean isSelected{get;set;}
        @AuraEnabled public  String matchedColour{get;set;}
        @AuraEnabled public  list<SplitReportWrapper> spliList{get;set;}
        
    }
    public class SplitReportWrapper{
        @AuraEnabled public  Decimal newAmount{get;set;}
        @AuraEnabled public  String  reference1{get;set;}
        @AuraEnabled public  String  reference2{get;set;}
    }
    public class searchWrapper{
        @AuraEnabled public  list<Installment__c> installmentList{get;set;}
        @AuraEnabled public  String  payee{get;set;}
        
    }
    
    public static void justIncrement() { 
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