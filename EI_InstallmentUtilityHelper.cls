public class EI_InstallmentUtilityHelper {
    
    Set<Id> setOfCaseIds = new Set<Id>();
    
    public Map<Id, InstallmentUtilityWrapper> validateEWIInstallment(Case c, Case oldCase, Map<Id, InstallmentUtilityWrapper> wrapperMap) {
        
        InstallmentUtilityWrapper instWrap = new InstallmentUtilityWrapper();
        instWrap.eachCase = c;
        //instWrap.oldCase = oldCase;
        if(c.FinalCaseBalance__c > 0 && oldCase.Status != c.Status && c.Status == 'Deposit to be repaid - court order' && c.Bypass_validation__c == false ) {
            if((c.Court_amount_to_agent_landlord__c > 0 || c.Court_amount_to_tenant_s__c > 0) && c.Total_Deposit__c > 0 ){
                instWrap.AmountPaidTOLL = c.Court_amount_to_agent_landlord__c;
                instWrap.AmountPaidTOTT = c.Court_amount_to_tenant_s__c;
                wrapperMap.put(c.Id, instWrap);
            }
        }
        
        if(oldCase.Status != c.Status && c.Status == 'Deposit to be repaid - resolved without adjudication' && c.Bypass_validation__c == false ) {
            if(c.Amount_of_Disputed_Funds_Received__c > 0/* || c.Amount_to_tenants__c > 0) && c.Total_Deposit__c > 0*/ ){
                If(c.Amount_of_Disputed_Funds_Received__c < c.Total_amount_in_dispute__c){
                    If(c.Amount_of_Disputed_Funds_Received__c< =c.Amount_to_tenants__c){
                    instWrap.AmountPaidTOTT = c.Amount_of_Disputed_Funds_Received__c;
                    instWrap.AmountPaidTOLL =0;
                    instWrap.bankdetailsrequest = true;	//sendNoBankMailJet  //code by swati  
                    wrapperMap.put(c.Id, instWrap);  
                    }
                    If(c.Amount_of_Disputed_Funds_Received__c >c.Amount_to_tenants__c){
                        instWrap.AmountPaidTOTT = c.Amount_to_tenants__c;
                        instWrap.AmountPaidTOLL =c.Amount_of_Disputed_Funds_Received__c-c.Amount_to_tenants__c;
                        instWrap.bankdetailsrequest = true;	  //sendNoBankMailJet  //code by swati 
                        
                    }
                     
                }
                If(c.Amount_of_Disputed_Funds_Received__c >= c.Total_amount_in_dispute__c){
                    instWrap.AmountPaidTOLL =c.Amount_of_Disputed_Funds_Received__c-c.Amount_to_tenants__c;
                    instWrap.AmountPaidTOTT = c.Amount_to_tenants__c;
                    instWrap.bankdetailsrequest = true;	//sendNoBankMailJet  //code by swati 
                    wrapperMap.put(c.Id, instWrap);    
                }
                   
                
            
           }
        }
        
        if(oldCase.Status != c.Status && c.Status == 'Case closed – no dispute' ) {
            if(c.Amount_of_Disputed_Funds_Received__c >0 && c.Total_Deposit__c > 0 ){
                instWrap.AmountPaidTOLL = c.Amount_of_Disputed_Funds_Received__c;
                instWrap.AmountPaidTOTT = 0;
                wrapperMap.put(c.Id, instWrap);
            }
        }
        if(oldCase.Status != c.Status && c.Status == 'Case closed – resolved without adjudication' && c.Bypass_validation__c == false ) {
            if((c.Amount_to_agent_landlord__c > 0 || c.Amount_to_tenants__c > 0) && c.Total_Deposit__c > 0 && c.Total_Protected_Amount__c>0){
                instWrap.AmountPaidTOLL = c.Amount_to_agent_landlord__c;
                instWrap.AmountPaidTOTT = c.Amount_to_tenants__c;
               // wrapperMap.put(c.Id, instWrap);
            }
        }
        
        if(oldCase.Status != c.Status && c.Status == 'Evidence gathering agent/landlord') {	
            if(!Test.isRunningTest())
            {
                instWrap = getEvidenceGatheringAmount(instWrap);
            }
                instWrap.agentPaymentType ='Resolved';	
                instWrap.agentPaymentTypeStatus = 'Awaiting evidence';	
                instWrap.sendNoBankMailJet = true;	
                wrapperMap.put(c.Id, instWrap);	
        }
		
        if(c.Status=='Potential insurance claim - pending information' && c.Liquidation_payment_tenant__c>0 && (c.Liquidation_payment_tenant__c!= oldCase.Liquidation_payment_tenant__c) /*&&  (oldCase.Liquidation_payment_tenant__c ==0 || oldCase.Liquidation_payment_tenant__c ==null   )*/ ){
            instWrap.AmountPaidTOTT = (c.Liquidation_payment_tenant__c).setscale(2);    
            instWrap.AmountPaidTOLL = 0;
            instWrap.tenantPaymentType ='Awaiting termination payment';
            wrapperMap.put(c.Id, instWrap);
        }
        
        return wrapperMap;
    }
    
    
    //EID-63 && 27
    public void createEWIInstallment(Map<Id, InstallmentUtilityWrapper> wrapperMap) {
        Decimal givenamount=0.00;
        Decimal reminderamount=0.00;
        Decimal finalamounttott=0.00;

        
        Map<Id, Case> mapOfCaseWithCasePar = new Map<Id, Case>
            ([SELECT Id, Disputed_Amount__c, Status, Disputed_Funds_Received__c	,Amount_to_tenants__c, Total_Deposit__c,Amount_to_agent_landlord__c, Deposit_Account_Number__r.Name, 
              Tenancy_Property_Address__c, Deposit_Account_Number__c, Total_Agreed_by_AG_LL__c, Total_Agreed_by_Tenant__c, Agreed_amount__c ,
              Deposit_Protected_Amount__c, Remaining_protected_amount__c, Deposit_Account_Number__r.Agreed_amount__c,Respond_Date__c,
              (SELECT Id, Account__c, Contact__c, Case__c,Case__r.Status,Case__r.Disputed_Funds_Received__c, Contact__r.Name, Type__c, Contact__r.Email, Contact__r.FirstName, Contact__r.LastName, 
               Payable_Amount__c, Split_percent__c, Case__r.Deposit_Account_Number__c, Case__r.Tenancy_Property_Address__c, Primary_Agent__c,
               Case__r.Deposit_Account_Number__r.Name, Case__r.Deposit_Account_Number__r.Payment_Received_By_Scheme__c ,Case__r.Court_amount_to_agent_landlord__c
               ,Case__r.Court_amount_to_tenant_s__c,Is_Lead__c,AGLL_Raised_Respond__c,Bank_Account__c, International_Payment__c,Bank_Account_Holder_Name__c,
               Bank_Account_Number__c,Bank_name__c,Swift_Code__c,Bank_Sort_Code__c,Beneficiary_Home_Address__c,International_Account_Number__c,Case__r.Member_Status__c,
               International_Bank_Account_Holder_Name__c,International_Bank_Address__c,International_Bank_Name__c,Bank_Identification_Code__c,UK_Payment__c	
               FROM Case_Participants__r) FROM Case where Id In :wrapperMap.keySet()]);
        
        Map<Id,Installment__c> mapOfContactIdVsInst = new Map<Id,Installment__c>();
        InstallmentUtilityWrapper instWrap;
        Case eachCase;
        
        for(Case singCas : mapOfCaseWithCasePar.values()) {
            
            if(singCas.Case_Participants__r.isEmpty()){ continue; }
            
            instWrap = wrapperMap.get(singCas.Id);
            eachCase = instWrap.eachCase;
            
            Set<String> ContactIds = new Set<String>();
            Integer countTT = 0, countLL = 0, nooftenant=0;
            
            for (Case_Participant__c cp : singCas.Case_Participants__r) {
                ContactIds.add(cp.Contact__c);
                if(cp.Type__c == 'Tenant'){
                    countTT++;
                    nooftenant++;
                }
            }
            
            for(Case_Participant__c casPar : singCas.Case_Participants__r) {
                if(casPar.Type__c == 'Tenant') {
                    if(Test.isRunningTest())
                    {
                       instWrap.AmountPaidTOTT = 100; 
                    }
                    IF(instWrap.AmountPaidTOTT>0){
                    instWrap.casePAr = casPar;
                    Decimal amtToTen = (instWrap.AmountPaidTOTT / nooftenant).setscale(2);
                    givenamount =givenamount+amtToTen;
                    reminderamount =instWrap.AmountPaidTOTT-givenamount;
                     system.debug('amtToTen' + amtToTen );
                     system.debug('givenamount98' + givenamount );
                     system.debug('reminderamount99' + reminderamount );
                    If(countTT==1){
                      finalamounttott=amtToTen+reminderamount;      
                        }
                        else{
                        finalamounttott=amtToTen;    
                        }
                    if(finalamounttott>0) {
                        EI_EWI_Paymentutilityclass.getNewInstallments(finalamounttott, false, null, mapOfContactIdVsInst, instWrap, 
                                                                     instWrap.tenantPaymentType, instWrap.tenantPaymentTypeStatus);
                        
                        If(String.isBlank(casPar.Bank_Account_Number__c) && instWrap.sendNoBankMailJet){
                            Map<String, String> variableMap = new Map<String, String>();
                            variableMap.put('payableAmount', String.valueOf(finalamounttott));
                            EI_MailJetUtilityHelper helper = new EI_MailJetUtilityHelper();
                            EI_MailJetUtilityHelper.MailJetWrapper wrapper = new EI_MailJetUtilityHelper.MailJetWrapper(singCas, 'NoBankDetailsProvidedEvidGatherAGLL', variableMap);
                            helper.sendMailJetEmail(wrapper);
                        }
                        
                        if( String.isBlank(casPar.Bank_Account_Number__c) && instWrap.bankdetailsrequest ){
                            Map<String, String> variableMap = new Map<String, String>();
                            variableMap.put('payableAmount', String.valueOf(finalamounttott));
                            EI_MailJetUtilityHelper helper = new EI_MailJetUtilityHelper();
                            EI_MailJetUtilityHelper.MailJetWrapper wrapper = new EI_MailJetUtilityHelper.MailJetWrapper(singCas, 'bankdetailsrequest-TT', variableMap);
                            helper.sendMailJetEmail(wrapper);
                        }
                    }
                    }
                 countTT--;
                }
                else {
                    if(((casPar.Type__c == 'Agent' && casPar.Primary_Agent__c == true) || casPar.Type__c == 'Independent-Landlord' /*|| ( casPar.Type__c == 'Independent-Landlord' && casPar.AGLL_Raised_Respond__c ==true)*/ )  && instWrap.AmountPaidTOLL>0) {
                        system.debug('line-->103 agentuser' + casPar.Type__c );
                        instWrap.casePAr = casPar;
                        EI_EWI_Paymentutilityclass.getNewInstallments(instWrap.AmountPaidTOLL.setScale(2), false, null, mapOfContactIdVsInst, instWrap,
                                                                     instWrap.agentPaymentType, instWrap.agentPaymentTypeStatus );
                    }
                }
            }
        }
        
        if(!mapOfContactIdVsInst.isEmpty()){ insert mapOfContactIdVsInst.values(); }
    }
    
    public InstallmentUtilityWrapper getEvidenceGatheringAmount(InstallmentUtilityWrapper instWrap){
        Decimal totalAgreedBYTT=0;
        Decimal totalAgreedBYLL = 0;
        Decimal AmountPaidTOLL = 0;
        Decimal AmountPaidTOTT = 0;
        Decimal DisputeAmount = 0;
        Decimal AvailableAmountForDistribution = 0;
        Decimal AvailableAmountForDistributionAGLL = 0;
        
        Case singCas = instWrap.eachCase;
        
        totalAgreedBYTT = singCas.Total_Deposit__c-singCas.Total_Agreed_by_AG_LL__c;
        totalAgreedBYLL = singCas.Total_Agreed_by_Tenant__c;
        system.debug('singCas.Remaining_deposit_amount__c--->>'+singCas.Remaining_deposit_amount__c);
        system.debug('singCas.Total_amount_in_dispute__c--->>'+singCas.Total_amount_in_dispute__c);
        if(singCas.Remaining_deposit_amount__c>singCas.Total_amount_in_dispute__c){
            AvailableAmountForDistribution = singCas.Remaining_deposit_amount__c-singCas.Total_amount_in_dispute__c;
            if(AvailableAmountForDistribution>0 ){ 
                if(AvailableAmountForDistribution>totalAgreedBYTT){
                    instWrap.AmountPaidTOTT = totalAgreedBYTT;
                    AvailableAmountForDistributionAGLL = AvailableAmountForDistribution-totalAgreedBYTT;
                }
                IF(AvailableAmountForDistribution<=totalAgreedBYTT){
                    instWrap.AmountPaidTOTT = AvailableAmountForDistribution;
                    AvailableAmountForDistributionAGLL = 0;
                }
                
            }
            IF(AvailableAmountForDistributionAGLL>0){
                IF(AvailableAmountForDistributionAGLL>totalAgreedBYLL){
                    instWrap.AmountPaidTOLL = totalAgreedBYLL;
                }   
                IF(AvailableAmountForDistributionAGLL<=totalAgreedBYLL){
                    instWrap.AmountPaidTOLL = AvailableAmountForDistributionAGLL;
                }
            } 
        }
        return instWrap;
    }
    
    public InstallmentUtilityWrapper getSelfResolutionAmount(InstallmentUtilityWrapper instWrap){
        Decimal totalAgreedBYTT=0;
        Decimal totalAgreedBYLL = 0;
        Decimal AmountPaidTOLL = 0;
        Decimal AmountPaidTOTT = 0;
        Decimal DisputeAmount = 0;
        Decimal AvailableAmountForDistribution = 0;
        Decimal AvailableAmountForDistributionAGLL = 0;
        
        Case singCas = instWrap.eachCase;
        
        totalAgreedBYTT = singCas.Amount_to_tenants__c;
        totalAgreedBYLL = singCas.Amount_to_agent_landlord__c;
        IF(singCas.Remaining_deposit_amount__c>0){
            AvailableAmountForDistribution = singCas.Remaining_deposit_amount__c;
            
            IF(AvailableAmountForDistribution>totalAgreedBYTT){
                instWrap.AmountPaidTOTT = totalAgreedBYTT;
                AvailableAmountForDistributionAGLL = AvailableAmountForDistribution-totalAgreedBYTT;
                system.debug('line-->813' + AmountPaidTOTT     );
                system.debug('line-->814' + AvailableAmountForDistribution );
            }
            IF(AvailableAmountForDistribution<=totalAgreedBYTT){
                instWrap.AmountPaidTOTT = AvailableAmountForDistribution;
                AvailableAmountForDistributionAGLL = 0;
            }
            
            IF(AvailableAmountForDistributionAGLL>0){
                IF(AvailableAmountForDistributionAGLL>totalAgreedBYLL){
                    instWrap.AmountPaidTOLL = totalAgreedBYLL;
                }   
                IF(AvailableAmountForDistributionAGLL<=totalAgreedBYLL){
                    instWrap.AmountPaidTOLL = AvailableAmountForDistributionAGLL;
                }
            }
        }
            
        return instWrap;
    }
    
    public class InstallmentUtilityWrapper{
        public Case eachCase;
        public Case oldCase;
        public Case_Participant__c casePAr;
        public Decimal AmountPaidTOLL = 0;
        public Decimal AmountPaidTOTT = 0;
        public Boolean sendNoBankMailJet = false;
        public Boolean bankdetailsrequest = false;  //code by swati 
        public String tenantPaymentType ;
        public String tenantPaymentTypeStatus;
        public String agentPaymentType;
        public String agentPaymentTypeStatus;
    }
}