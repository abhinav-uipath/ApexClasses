/**********************************************************************************************************
* Author: Himanshi Bhoria
* Purpose: send email to landlord agent in duration of 10 , 15, 20 25 working dates of responsd date and case status is 
Evidence gathering agent/landlord
* Run Frequency:          
* *******************************************************************************************************/
/* Changes: 14 Sept 2022 Himanshi Bhoria-Added logic for EWI finance EID-30
*          22 Sept 2022 Himanshi Bhoria- Added Logic for EWI finance EID 118
* 
* ******************************************************************************************************/
global class EI_EWI_FinanceSendEmail implements Database.Batchable<sObject>, database.AllowsCallouts, Database.Stateful, Schedulable {
    
     public void execute(SchedulableContext SC){
        Database.executeBatch(new EI_EWI_FinanceSendEmail(), 100);
    }
    
    public static List<Holiday> holidayList;
    //to get the case recordTypeId
    Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Dispute EW Insured').getRecordTypeId();
    public EI_MailJetUtilityHelper helper = new EI_MailJetUtilityHelper();
    //public Map<String, Map<String, String>> emailsubject = helper.getSubjects();
    Public List<Case> agllCaseList = new List<Case>();
    Public Map<Id, Case> caseMap = new Map<Id, Case>();
    Public Map<Id, String> keyMap = new Map<Id, String>();
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query ='select Id,Status,Respond_date__c,OwnerId,V_External_Id__c,Evidence_Gathering_Start_Date__c,Deposit_repaid_Start_Date__c,Tenancy_Property_Address__c,Resolved_Without_Adjudication_Reason__c,'
            + ' Disputed_Funds_Received__c,Stop_chaser_e_mails__c,Consent_withdrawn_date__c,Evidence_of_court_action_received__c,Dispute_Reference__c,Previous_owner__c,Disputed_Funds_Required__c,'
            +' AGLL_Respond_Evidance_Gathering__c,TT_respond_evidence_gathering__c,Counter__c,Deposit_Account_Number__r.Property_Address_WO_Country__c,Awaiting_review_date__c'
            + ' from Case where RecordtypeId=:devRecordTypeId ';  //( Evidence_Gathering_Start_Date__c!= Null OR Deposit_repaid_Start_Date__c!=Null)  AND
        return database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Case> caseList){
        Set<Id> setCaseIds = new Set<Id>();
        Set<Id> setCreditIds = new Set<Id>();
        List<Case> listAllDisputedCase= new List<Case>();
        try{
            
            Map<Id,Case> mapCase = new Map<Id, Case>(caseList);
            
            system.debug('Debugg >>>1');
            listAllDisputedCase=[select Id,Status,Respond_date__c,OwnerId,Evidence_Gathering_Start_Date__c,Disputed_Funds_Received__c, Stop_chaser_e_mails__c,Resolved_Without_Adjudication_Reason__c,
                                 Deposit_repaid_Start_Date__c,Consent_withdrawn_date__c,Evidence_of_court_action_received__c,Dispute_Reference__c,Disputed_Funds_Required__c,
                                 Previous_owner__c,AGLL_Respond_Evidance_Gathering__c,TT_respond_evidence_gathering__c,Counter__c,Awaiting_review_date__c,
                                 Deposit_Account_Number__r.Property_Address_WO_Country__c,V_External_Id__c,Tenancy_Property_Address__c,
                                 (select Id,Type__c, Case__c,Account__c,Bank_Account__c,Account__r.Name, Account__r.Email__c,Bank_Account__r.Name,
                                  Account__r.PersonEmail, Contact__c,Case__r.Amount_to_tenants__c, Contact__r.Email, Contact__r.Name, 
                                  Access_Code__c From Case_Participants__r) from Case 
                                 where RecordtypeId=:devRecordTypeId  //(Evidence_Gathering_Start_Date__c!= null OR Deposit_repaid_Start_Date__c!= null)
                                 AND Id=: mapCase.keySet() ];
            
            for(Case eachCase: listAllDisputedCase){
                //EID-30
                date fromDate ;
                //FOR EID-1261
                //Updated the status Review Complete to Evidence Review Complete
                //Case Assigned to Adjudicator to Adjudication
                //Decision issued - dispute monies outstanding 
                if((eachCase.status=='Evidence gathering agent/landlord' || eachCase.status=='Evidence gathering tenant'
                    || eachCase.status=='Evidence review complete' || eachCase.status=='Adjudication' || eachCase.status == 'Decision issued – dispute monies outstanding') && eachCase.Evidence_Gathering_Start_Date__c!= null)
                {
                    fromDate = eachCase.Evidence_Gathering_Start_Date__c;
                }else if(eachCase.status=='Awaiting Review'){
                      fromDate = eachCase.Awaiting_review_date__c;
                }
                if(((eachCase.status=='Evidence gathering agent/landlord' || eachCase.status=='Evidence gathering tenant'
                     || eachCase.status=='Evidence review complete' || eachCase.status=='Adjudication' || eachCase.status == 'Decision issued – dispute monies outstanding') && eachCase.Evidence_Gathering_Start_Date__c!= null)
                   || eachCase.status=='Awaiting Review')
                {
                    System.debug(eachCase.dispute_reference__c + ' => ' + eachCase.Evidence_Gathering_Start_Date__c );
                    //Date of 10th Working Day 
                    Date check_10_workingdaycompleted = CalculateWorkingDaysUtility.calculateWorkingDaysBetweenTwoDates(fromDate,11); // eachCase.Evidence_Gathering_Start_Date__c.addDays(10);
                    system.debug('check_10_workingdaycompleted>>>> '+check_10_workingdaycompleted);
                    //Date of 15th Working Day
                    Date check_15_workingdaycompleted = CalculateWorkingDaysUtility.calculateWorkingDaysBetweenTwoDates(fromDate,15); // eachCase.Evidence_Gathering_Start_Date__c.addDays(15);
                    system.debug('check_15_workingdaycompleted>>>> '+check_15_workingdaycompleted);
                    //Date of 20th Working Day
                    Date check_20_workingdaycompleted = CalculateWorkingDaysUtility.calculateWorkingDaysBetweenTwoDates(fromDate,20); // eachCase.Evidence_Gathering_Start_Date__c.addDays(20);
                    system.debug('check_20_workingdaycompleted>>>> '+check_20_workingdaycompleted);
                    //Date of 25th Working Day 
                    Date check_25_workingdaycompleted = CalculateWorkingDaysUtility.calculateWorkingDaysBetweenTwoDates(fromDate,25); // eachCase.Evidence_Gathering_Start_Date__c.addDays(25);
                    system.debug('check_25_workingdaycompleted>>>> '+check_25_workingdaycompleted);
                    
                    //25 Working Days and status is Evidence gathering agent/landlord and No monies is allocated to the case
                    if(system.today() == check_25_workingdaycompleted && eachCase.Stop_chaser_e_mails__c == false){
                        system.debug('++entry25');
                        caseMap.put(eachCase.Id, eachCase);
                        keyMap.put(eachCase.Id, 'FinanceEID30Batch');
                        agllCaseList.add(eachCase);
                    }
                    
                    //20 Working Days and status is Evidence gathering agent/landlord and No monies is allocated to the case
                    else if(system.today() == check_20_workingdaycompleted && eachCase.Stop_chaser_e_mails__c == false){
                        system.debug('++entry20');
                        caseMap.put(eachCase.Id, eachCase);
                        keyMap.put(eachCase.Id, 'FinanceEID30Batch1');
                        agllCaseList.add(eachCase);
                    }
                    
                    //15 Working Days and status is Evidence gathering agent/landlord and No monies is allocated to the case
                    else if(system.today() == check_15_workingdaycompleted && eachCase.Stop_chaser_e_mails__c == false){
                        system.debug('++entry15');
                        caseMap.put(eachCase.Id, eachCase);
                        keyMap.put(eachCase.Id, 'FinanceEID30Batch2');
                        system.debug('++entry15--');
                        agllCaseList.add(eachCase);
                    }
                    
                    //Email After 10 Working Days and status is Evidence gathering agent/landlord and No monies is allocated to the case
                    else if(system.today() == check_10_workingdaycompleted && eachCase.Stop_chaser_e_mails__c == false){
                        system.debug('++entry10');
                        caseMap.put(eachCase.Id, eachCase);
                        keyMap.put(eachCase.Id, 'FinanceEID30Batch3');
                        agllCaseList.add(eachCase);
                    } 
                }
                
                
                else if((eachCase.status=='Deposit closed - deposit repaid in part' && eachCase.Deposit_repaid_Start_Date__c!= null) 
                        || eachCase.Status == 'Deposit closed - unable to repay' 
                        || eachCase.Status == 'Decision issued – dispute monies outstanding' || eachCase.Status == 'Decision issued – with legal' 
                        || eachCase.Status == 'Decision issued – Insurance claim' || eachCase.Status == 'Case closed – resolved without adjudication' ){
                            //EID 118
                            System.debug('');
                            //Date of 112th Working Day by adding 5 days in Respond Date
                            Date check_112_workingdaycompleted = eachCase.Deposit_repaid_Start_Date__c.addDays(112); // calculateWorkingDaysBetweenTwoDates(eachCase.Deposit_repaid_Start_Date__c,112);
                            system.debug('Date>>>>'+check_112_workingdaycompleted);
                            //Date of 84th Working Day by adding 5 days in Respond Date
                            Date check_84_workingdaycompleted = eachCase.Deposit_repaid_Start_Date__c.addDays(84); // calculateWorkingDaysBetweenTwoDates(eachCase.Deposit_repaid_Start_Date__c,84);
                            system.debug('Line 31'+check_84_workingdaycompleted);
                            //Date of 56th Working Day by adding 10 days in Respond Date
                            Date check_56_workingdaycompleted = eachCase.Deposit_repaid_Start_Date__c.addDays(56); // calculateWorkingDaysBetweenTwoDates(eachCase.Deposit_repaid_Start_Date__c,56);
                            //Date of 28th Working Day by adding 15 days in Respond Date
                            Date check_28_workingdaycompleted = eachCase.Deposit_repaid_Start_Date__c.addDays(28); // calculateWorkingDaysBetweenTwoDates(eachCase.Deposit_repaid_Start_Date__c,28);
                            System.debug('check_28_workingdaycompleted => ' + check_28_workingdaycompleted);
                            
                            system.debug('----'+eachCase.status); //Deposit closed - deposit repaid in part
                            
                            system.debug('----+++'+eachCase.status);
                            if(system.today() == check_112_workingdaycompleted ){
                                caseMap.put(eachCase.Id, eachCase);
                                keyMap.put(eachCase.Id, 'FinanceEID118Batch1'); 
                            }
                            
                            else if(system.today() == check_84_workingdaycompleted ){
                                caseMap.put(eachCase.Id, eachCase);
                                keyMap.put(eachCase.Id, 'FinanceEID118Batch2'); 
                                
                            }
                            
                            else if(system.today() == check_56_workingdaycompleted ){
                                system.debug('Line>>>>>> 130');
                                caseMap.put(eachCase.Id, eachCase);
                                keyMap.put(eachCase.Id, 'FinanceEID118Batch3');
                                
                            }
                            
                            else if(system.today() == check_28_workingdaycompleted ){
                                system.debug('Line>>>>>> 125');
                                caseMap.put(eachCase.Id, eachCase);
                                keyMap.put(eachCase.Id, 'FinanceEID118Batch4'); 
                                
                            } 
                        }
            } 
            
        }
        
        
        
        catch(DmlException ex){
            Insert (new Error_Log__c(Message_Long__c='Issue is: '
                                     + ex.getMessage() + '************ StackTrace String : ' + ex.getStackTraceString()
                                     + ' at Line Number- ' + ex.getLineNumber(),Method_Name__c='Class: EI_EWI_FinanceSendEmail '));
            
            
            
        }
    }  
    global void finish(Database.BatchableContext BC) {
        EI_MailJetUtilityHelper.MailJetWrapper wrapper = new EI_MailJetUtilityHelper.MailJetWrapper();
        wrapper.keyMap = keyMap;
        wrapper.newMap = caseMap;
        helper.sendMailJetEmail(wrapper);
        system.debug('agll---'+agllCaseList);
        if(!agllCaseList.isEmpty()){ EI_EWI_CaseTriggerHandler.process_credit_control(agllCaseList,new Map<Id,Case>(), keyMap, helper.mapSubjects); }
    }
    
    public static Date calculateWorkingDaysBetweenTwoDates(Date startDate, Integer noOfDays) {
        if(startDate == null) {
            return null;
        }
        if(holidayList == null || holidayList.isEmpty()) {
            holidayList = [Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h];
        }
        
        Integer allWorkingDays=0;
        Integer totalDays = 1;
        while(allWorkingDays<=noOfDays) {
            if(checkifItisWorkingDay(startDate.addDays(totalDays),holidayList)) {
                allWorkingDays++;
                if(allWorkingDays==noOfDays)
                    break;
            }
            totalDays++;
        }
        while(!checkifItisWorkingDay(startDate.addDays(totalDays), holidayList)) {
            totalDays++;
        }
        return startDate.addDays(totalDays);
    }
    
    public static boolean checkifItisWorkingDay(Date currentDate, List<Holiday> holidays) {
        Date weekStart  = currentDate.toStartofWeek();
        for(Holiday hDay:holidays) {
            if(currentDate.daysBetween(hDay.ActivityDate) == 0) {
                return false;
            }
        }
        if(weekStart.daysBetween(currentDate) == 5 || weekStart.daysBetween(currentDate) == 6) {
            return false;
        } else {
            return true;    
        }
    }
    
}