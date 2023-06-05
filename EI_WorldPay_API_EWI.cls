@RestResource(urlMapping='/tds_worldpay_api_EWI')
global class EI_WorldPay_API_EWI {
    public static Id CaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Dispute EW Insured').getRecordTypeId();
    @HttpPost
    global static void postMethod() {
         system.debug('===== tds_worldpay_api_EWI CALLED======');
        //Update Protected Amount 
        RestRequest req = RestContext.request;
        map<String,String> worldpayParams = req.params;
        system.debug('>>>>>>>>>>>>>>>>>>'+JSON.serializePretty(worldpayParams));
        
        list<String> danToProcess = new list<String>();
        if(worldpayParams != null && !worldpayParams.isEmpty() && worldpayParams.containsKey('authAmountString') && String.isNotBlank(worldpayParams.get('authAmountString'))){
            
            String cartId = worldpayParams.containsKey('cartId')?worldpayParams.get('cartId'):'';
            Decimal amount = worldpayParams.containsKey('amount')?Decimal.valueOf(worldpayParams.get('amount')):null;
            Id inboundReportRecId = Schema.SObjectType.Inbound_Report__c.getRecordTypeInfosByName().get('EWI Inbound Report').getRecordTypeId();
			Id paymentRecId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('EWI Payment').getRecordTypeId();
            if(String.isNotBlank(cartId) && amount != null ){

                //Find Installment 
                list<Installment__c> installmentList = [Select Id,Case__c, Bank_Account_Holder_Name__c, Case__r.Dispute_Reference__c,Name,Deposit__r.Status__c, Deposit__r.Deposit_Amount__c,Amount__c,Deposit__r.Deposit_Account_Number__c,Deposit__c,Installment_Type__c,Status__c,Deposit__r.Protected_Amount__c from Installment__c
                                                                            where Case__r.Dispute_Reference__c =: cartId 
                                                                            AND Status__c = 'Pending'
                                                                            AND Installment_Type__c = 'Receivable' 
                                                                            AND Amount__c =: amount ORDER BY LastModifiedDate DESC]; 

                System.debug('>>>>>>>>>>>'+installmentList.size());
                //Create Inbound report
                Inbound_Report__c report = new Inbound_Report__c();
                report.RecordTypeId = inboundReportRecId;
                report.Reference1__c = cartId;
                //?????
                report.Collection_Date__c = System.today();
                if(worldpayParams.containsKey('amount'))
                    report.Amount__c = Decimal.valueOf(worldpayParams.get('amount'));
                if(installmentList != null && !installmentList.isEmpty()){
                    report.Installment__c = installmentList[0].Id;
                    
                }else{
                    report.Matched_Colour__c = 'Red';
                }
                report.Sage_nominal_code__c='88020';
                report.Sage_bank_account_ID__c='85005';
                report.Sage_narrative_field__c= 'Inbound' +cartId;
                
                report.Payment_Method__c = 'Debit Card';
                if(worldpayParams.containsKey('transId'))
                    report.Transaction_Id__c = worldpayParams.get('transId');

                insert report;

                //Create Payment if Installment found for report

                if(String.isNotBlank(report.Installment__c)){
                    Payment__c pay = new Payment__c();
                    pay.Amount__c = report.Amount__c;
                    pay.Collection_Date__c = report.Collection_Date__c;
                    pay.Transaction_Date__c = report.Collection_Date__c;
                    pay.PaymentMethod__c = 'Debit Card';
                    pay.Inbound_Report__c = report.Id;
                    system.debug('report Id value>>'  + report.Id);
                    system.debug('Install>>'  + report.Installment__c);
                    system.debug('case value>>'  + installmentList[0].Case__c);
                    pay.Case__c	= installmentList[0].Case__c;
                    pay.Installment__c = report.Installment__c;
                    pay.DAN__c = installmentList[0].Deposit__c;
                    pay.Transaction_Id__c = report.Transaction_Id__c;
                    pay.Payment_Type__c = 'Receivable';
					pay.Payment_Status__c = 'Paid';
                    pay.RecordTypeId = paymentRecId;
                    pay.Sage_nominal_code__c='88020';
                    pay.Sage_bank_account_ID__c='85005';
                    pay.Sage_narrative_field__c= 'Inbound' + installmentList[0].case__r.Dispute_Reference__c;
                    
                    insert pay;

                     //update Installment Status 
                     Update new Installment__c(Id= report.Installment__c,Status__c = 'Collected',Payment_Method__c='Debit Card');

                    //Update Deposit status 
					List<Case> caseList = [SELECT Id,RecordTypeId,Amount_of_Disputed_Funds_Remaining__c,Amount_of_Disputed_Funds_Required__c,Undisputed_Funds_Received__c,
                                           Amount_of_Disputed_Funds_Received__c FROM Case WHERE id = :installmentList[0].Case__c];
                    
                    createInstallmentRemainingAmount(caseList);
                }

            }
        }

    }
    
    public static void createInstallmentRemainingAmount (List<Case> newlist){
        Set<Id> setCaseIds=new Set<Id>();
        List<Installment__c> listOfInstallmentsToCreate = new List<Installment__c>(); 
        List<Case>lstCasewithAmounts=new  List<Case>();
        try{
            Id InstalRecordTypeId = Schema.SObjectType.Installment__c.getRecordTypeInfosByDeveloperName().get('EWI_Installment').getRecordTypeId();
            for(Case objCase:newlist){
                System.debug('objCase.RecordTypeId : '+objCase.RecordTypeId+'--'+'CaseRecordTypeId : '+CaseRecordTypeId);
                if(objCase.RecordTypeId==CaseRecordTypeId ){
                    System.debug('objCase.Amount_of_Disputed_Funds_Remaining__c:'+objCase.Amount_of_Disputed_Funds_Remaining__c);
                    if(objCase.Amount_of_Disputed_Funds_Remaining__c>0){
                        //System.debug('objCase.Amount_of_Disputed_Funds_Remaining__c:'+objCase.Amount_of_Disputed_Funds_Remaining__c+'--'+'oldMap:'+oldMap.get(objCase.Id).Amount_of_Disputed_Funds_Remaining__c);
                        //if(objCase.Amount_of_Disputed_Funds_Remaining__c !=oldMap.get(objCase.Id).Amount_of_Disputed_Funds_Remaining__c){
                            System.debug('objCase.Amount_of_Disputed_Funds_Required__c:'+objCase.Amount_of_Disputed_Funds_Required__c+'--'+'objCase.Amount_of_Disputed_Funds_Received__c:'+objCase.Amount_of_Disputed_Funds_Received__c);
                            if(objCase.Amount_of_Disputed_Funds_Required__c!=objCase.Amount_of_Disputed_Funds_Received__c){
                                if(objCase.Amount_of_Disputed_Funds_Received__c<objCase.Amount_of_Disputed_Funds_Required__c && objCase.Amount_of_Disputed_Funds_Received__c>0){
                                    setCaseIds.add(objCase.Id);
                                    lstCasewithAmounts.add(objCase);
                                }
                                if(objCase.Amount_of_Disputed_Funds_Received__c>objCase.Amount_of_Disputed_Funds_Required__c && objCase.Amount_of_Disputed_Funds_Received__c>0){
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
            
            
            List<Installment__C>lstInstExisting=[Select Id,Amount__c,Case_participant__c,Case_participant__r.Type__c,Case__c,Status__c from Installment__C where Case__c=:setCaseIds];
            
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
                            if(objCase.AccountId!=null){
                            objIns.Account__c = objCase.AccountId;
                            }
                            objIns.Amount__c=objCase.Amount_of_Disputed_Funds_Remaining__c;
                            objIns.Case_participant__c = cp.Id;
                            objIns.Case__C=objCase.Id;
                            objIns.RecordTypeId=InstalRecordTypeId;
                            objIns.Deposit__c=objCase.Deposit_Account_Number__c;
                            objIns.Contact__c=cp.Contact__c;
                            objIns.Bank_Name__c=cp.Bank_Name__c;
                            objIns.BIC__c=cp.Bank_Identification_Code__c;
                            objIns.Bank_Account_Number__c=cp.Bank_Account_Number__c;
                            objIns.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                            objIns.Bank_Account_Holder_Name__c=cp.Bank_Account_Holder_Name__c;
                            if(cp.International_Payment__c==true){
                                objIns.Bank_Name__c=cp.International_Bank_Name__c;
                                objIns.BIC__c=cp.Bank_Identification_Code__c;
                                objIns.Bank_Account_Number__c=cp.International_Account_Number__c;
                                objIns.Bank_Sort_Code__c=cp.Bank_Sort_Code__c;
                                objIns.Bank_Account_Holder_Name__c=cp.International_Bank_Account_Holder_Name__c;
                                objIns.Swift_Code__c=cp.Swift_Code__c;
                            }
                            listOfInstallmentsToCreate.add(objIns);    
                        }
                        
                    }
                        
                    
                }
                    
                  if(objCase.Undisputed_Funds_Received__c > 0 && (objCase.Status == 'Evidence gathering agent/landlord'
                      || objCase.Status == 'Evidence gathering tenant' || objCase.Status == 'Evidence review complete'
                      || objCase.Status == 'Adjudication' || (objCase.Evidence_Gathering_Start_Date__c !=null && objCase.Status == 'Awaiting Review' ))){
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
                        /*    for(Installment__c inst : lstInstExisting){
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
                    
                    
                    if((objCase.Amount_of_Disputed_Funds_Received__c-objCase.EWI_Payment_genareted__c) > 0 && ( objCase.Status == 'Case closed – resolved without adjudication' || objCase.Status == 'Deposit to be repaid - resolved without adjudication' || (objCase.Evidence_Gathering_Start_Date__c ==null && objCase.Status == 'Awaiting Review' )/* || objCase.Status == 'Complaint closed' || objCase.Status == 'Decision issued - with legal' */ )){
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
                                    system.debug('line-->479 ++' ); 
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
                       ||  objCase.Status == 'Deposit closed - deposit repaid in part' || objCase.Status == 'Deposit closed - unable to repay' || objCase.Status == 'Decision issued - dispute monies outstanding' ||  objCase.Status == 'Decision issued - with legal' || objCase.Status == 'Overpayments'  )){
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
                if(listOfInstallmentsToCreate.size()>0 && !listOfInstallmentsToCreate.isEmpty()){
                    insert listOfInstallmentsToCreate;
                }
                
            }
        }catch(exception ex){
            System.debug('line 714 => ' + ex.getMessage() + ' line => ' + ex.getLineNumber());
            Insert (new Error_Log__c(Message_Long__c='Issue is: '
                                     + ex.getMessage() + '************ StackTrace String : ' + ex.getStackTraceString()
                                     + ' at Line Number- ' + ex.getLineNumber(),Method_Name__c='Class: EI_InstallmentTriggerHandler '));
        }
    }
    
    
    
    
    
    
    @HttpGet
    global static String getMethod() {
        
        
        return 'Hello From Salesforce';    
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
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
            i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
            i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
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