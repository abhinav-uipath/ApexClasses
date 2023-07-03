public without sharing class ViewDepositController {
    
    public class depositWrapper {
        @AuraEnabled public List<Deposit__c> depositsOfAllStatus;
        @AuraEnabled public Integer countTransferredDeposit;
        
        public depositWrapper(List<Deposit__c> depositsOfAllStatus, Integer countTransferredDeposit) {
            this.depositsOfAllStatus = depositsOfAllStatus;
            this.countTransferredDeposit = countTransferredDeposit;
        }
        
    }
    
    @AuraEnabled
    public static List<Case> getChangeOverDetails() {
       String depositId;
        try {
        List<Case> tenantChangeOverCase = [SELECT Id, Deposit_Account_Number__r.Id, Deposit_Account_Number__r.Deposit_Account_Number__c, Status 
                                           FROM Case WHERE ownerId=: UserInfo.getUserId() AND status ='Tenant changeover initiated - tenant' AND 
                                           ChangeOver_Status__c ='Tenant Initiate'];
       
            if(tenantChangeOverCase.size()>0) {
                  return tenantChangeOverCase;
                
            } else {
                return null;
            }
        }
        catch(Exception e) {
           return null; 
        }
    }
    
    @AuraEnabled
    public static List<Deposit__c> getDeposit(string branchid) {
        Id accountid = [Select id,Contact.AccountId from User where Id=:Userinfo.getUserId()].Contact.AccountId;
        List<Deposit__c> depositList = new List<Deposit__c>();
        List<Branch__c> branch = new List<Branch__c>();
        if(branchid == null){
            branch =[Select Id from Branch__c where Id in (Select Branch__c from Branch_User_Mapping__c where User__c =: UserInfo.getUserId()) 
                     AND Is_Active__c = true ORDER BY Branch_Name__c Limit 1];
            System.debug('+++++++branch++'+branch);
            if(branch.size()>0) {
                depositList = [SELECT Id,Start_Date_Text__c,Name,Status__c,Deposit_Amount__c,Protected_Amount__c, Actual_Protected_Amount__c from Deposit__c 
                               where ((Customer__c =:accountid and Branch__c = NULL) or (Branch__c =: branch[0].id and Customer__c =:accountid )) ];//and Deposit_Transferred__c=false];
            }
            else {
                depositList = [SELECT Id,Name,Start_Date_Text__c,Status__c,Deposit_Amount__c,Protected_Amount__c, Actual_Protected_Amount__c from Deposit__c 
                               where Customer__c =:accountid and Branch__c = NULL ];//and Deposit_Transferred__c=false];
                
            }
        }
        else {
            depositList = [SELECT Id,Name,Start_Date_Text__c,Status__c,Deposit_Amount__c,Protected_Amount__c, Actual_Protected_Amount__c from Deposit__c 
                           where Branch__c =: branchid ];//and Deposit_Transferred__c=false];
        } 
        System.debug('+++++++depositList++'+depositList);
        
        return depositList;
    }
    
    @AuraEnabled
    public static Integer getAllTransferredDeposits() {
        User currentUser = [Select id,Contact.AccountId, Email from User where id=:Userinfo.getUserId()];
        List<Deposit__c> depositList = new List<Deposit__c>();
        depositList = [SELECT Id,Name,Start_Date_Text__c,Status__c,Protected_Amount__c, Actual_Protected_Amount__c,Deposit_Amount__c from Deposit__c 
                       where Deposit_Transferred__c=true and
                       (New_Customer_Email__c=:currentUser.Email or Deposit_Transferred_to_Account__c=:currentUser.Contact.AccountId)];
        system.debug('+++++++depositList++'+depositList);
        if(!depositList.isEmpty()){
            return depositList.size();
        }
        else{
            return 0;
        }
    }
    
    /* Get all deposits statuses */
    @AuraEnabled
    public static List<depositWrapper> getAllDeposits(String branchid) {
        
        List<depositWrapper> depoWrapper = new List<depositWrapper>();
        
        List<User> currentUser = [Select Id, Email, ContactId,Contact.createdBy.Name ,AccountId,createdBy.Contact.AccountId,Contact.AccountId,Contact.Account.Parent_person_account__c from User where Id=:Userinfo.getUserId() LIMIT 1];
        List<Deposit__c> depositList = new List<Deposit__c>();
        List<Branch__c> branch = new List<Branch__c>();
        Integer countTransferredDeposits = 0;
        Boolean additionalUser=false;
        if(currentUser[0].Contact.Account.Parent_person_account__c != NULL && currentUser[0].Contact.Account.Parent_person_account__c == currentUser[0].createdBy.Contact.AccountId){
            additionalUser = true;
        }
     
        
        if(branchid == null) {
            branch = [Select id from Branch__c where id in (Select Branch__c from Branch_User_Mapping__c where User__c =: UserInfo.getUserId()) 
                      AND Is_Active__c = true ORDER BY Branch_Name__c Limit 1];
            
            if(branch.size()>0) {
                depositList = [SELECT Id, Start_Date_Text__c, Deposit_Account_Number__c, Status__c, Start_Date__c, Deposit_Amount__c, 
                               (select id,Deadline_Date__c, Respond_Date__c from Cases__r limit 1),
                               Number_of_Tenants_Value__c, Property_Address_Without_Country__c, Protected_Amount__c, Actual_Protected_Amount__c, CreatedDate FROM Deposit__c 
                               WHERE (((Customer__c =:currentUser[0].Contact.AccountId ) AND Branch__c = NULL) OR 
                                      (Customer__c =:currentUser[0].Contact.AccountId AND Branch__c =: branch[0].Id)) 
                               AND Status__c IN ('Registered (not paid)', 'Awaiting payment', 'Deposits held by scheme', 
                                'Repayment requested by tenant', 'Repayment requested by agent/landlord', 'Repayment not agreed - In self-resolution', 
                                'Repayment not agreed - In dispute resolution', 'Repayment process', 'Deposits repayments concluded in the last year')
                               ORDER BY createdDate desc]; //and Deposit_Transferred__c=false
                
            } else {
                if(additionalUser){
                     depositList = [SELECT Id,Start_Date_Text__c,Deposit_Account_Number__c,Status__c,Start_Date__c,Deposit_Amount__c,
                                (select id,Deadline_Date__c, Respond_Date__c from Cases__r limit 1),
                                    Number_of_Tenants_Value__c,Property_Address_Without_Country__c,Protected_Amount__c, Actual_Protected_Amount__c,CreatedDate from Deposit__c 
                               WHERE (Customer__c =:currentUser[0].Contact.AccountId OR Customer__c =:currentUser[0].Contact.Account.Parent_person_account__c) and Branch__c = NULL AND 
                               Status__c IN ('Registered (not paid)', 'Awaiting payment', 'Deposits held by scheme', 
                                'Repayment requested by tenant', 'Repayment requested by agent/landlord', 'Repayment not agreed - In self-resolution', 
                                'Repayment not agreed - In dispute resolution', 'Repayment process', 'Deposits repayments concluded in the last year')
                               ORDER BY createdDate desc];
                    
                }else{
                    //  List<Contact> conOther = [Select id from Contact where Account.Parent_person_account__c =: currentUser[0].accountId];
                           depositList = [SELECT Id,Start_Date_Text__c,Deposit_Account_Number__c,Status__c,Start_Date__c,Deposit_Amount__c,
                                          (select id,Deadline_Date__c, Respond_Date__c from Cases__r limit 1),
                               Number_of_Tenants_Value__c,Property_Address_Without_Country__c,Protected_Amount__c, Actual_Protected_Amount__c,CreatedDate from Deposit__c 
                               WHERE (Customer__c =:currentUser[0].Contact.AccountId ) and Branch__c = NULL AND 
                               Status__c IN ('Registered (not paid)', 'Awaiting payment', 'Deposits held by scheme', 
                                'Repayment requested by tenant', 'Repayment requested by agent/landlord', 'Repayment not agreed - In self-resolution', 
                                'Repayment not agreed - In dispute resolution', 'Repayment process', 'Deposits repayments concluded in the last year')
                               ORDER BY createdDate desc]; //and Deposit_Transferred__c=false   
                }
                 
            }
            
        } else {
            depositList = [SELECT Id,Start_Date_Text__c,Deposit_Account_Number__c,Status__c,Start_Date__c,Deposit_Amount__c,
                           Number_of_Tenants_Value__c,Property_Address_Without_Country__c,Protected_Amount__c, Actual_Protected_Amount__c,CreatedDate from Deposit__c 
                           where Status__c IN ('Registered (not paid)', 'Awaiting payment', 'Deposits held by scheme', 
                            'Repayment requested by tenant', 'Repayment requested by agent/landlord', 'Repayment not agreed - In self-resolution', 
                            'Repayment not agreed - In dispute resolution', 'Repayment process', 'Deposits repayments concluded in the last year')
                            AND Branch__c =: branchid order by createdDate desc];//and Deposit_Transferred__c=false
        }
        
        List<Deposit__c> transferredDepoList = [SELECT Id, Name, Status__c FROM Deposit__c WHERE Deposit_Transferred__c=true AND 
                                                (New_Customer_Email__c=:currentUser[0].Email OR 
                                                 Deposit_Transferred_to_Account__c=:currentUser[0].Contact.AccountId)];
		        
        if(!transferredDepoList.isEmpty()) {
            countTransferredDeposits = transferredDepoList.size();
        }
        
        depoWrapper.add(new depositWrapper(depositList, countTransferredDeposits));
        System.debug('Line 131 weird -> '+depositList);
        System.debug('Line 132 weird -> '+countTransferredDeposits);
        System.debug('Line 133 weird -> '+depoWrapper[0].depositsOfAllStatus);
        System.debug('Line 134 weird -> '+depoWrapper.size());
        System.debug('Line 135 weird -> '+depoWrapper);
        
        return depoWrapper;
    }
    
    @AuraEnabled
    public static List<Deposit__c> getDepositsByStatus(String status, String branchid) {
     //   Id accountid = [Select id,Contact.AccountId from User where Id=:Userinfo.getUserId()].Contact.AccountId;
         List<User> currentUser = [Select Id, Email, ContactId,Contact.createdBy.Name ,createdBy.Contact.AccountId,Contact.AccountId,Contact.Account.Parent_person_account__c from User where Id=:Userinfo.getUserId() LIMIT 1];
      
           Boolean additionalUser=false;
        if(currentUser[0].Contact.Account.Parent_person_account__c != NULL && currentUser[0].Contact.Account.Parent_person_account__c == currentUser[0].createdBy.Contact.AccountId){
            additionalUser = true;
        }
        
        List<Deposit__c> depositList = new List<Deposit__c>();
        List<Branch__c> branch = new List<Branch__c>();
        system.debug('++++++++status+++'+status);
        String depositStatus = status.trim();
        if(branchid == null){
            branch =[Select id from Branch__c where id in (Select Branch__c from Branch_User_Mapping__c where User__c =: UserInfo.getUserId()) and Is_Active__c = true ORDER BY Branch_Name__c Limit 1];
            
            if(branch.size()>0){
                depositList = [SELECT Id, Start_Date_Text__c, Deposit_Account_Number__c, Property_Address__c, Start_Date__c, Deposit_Amount__c, 
                               Number_of_Tenants_Value__c, Property_Address_Without_Country__c, Protected_Amount__c, Actual_Protected_Amount__c, CreatedDate FROM Deposit__c 
                               WHERE Status__c=:depositStatus AND ((Customer__c =:currentUser[0].Contact.AccountID AND Branch__c = NULL) OR 
                                                                    (Branch__c =: branch[0].Id AND Customer__c =:currentUser[0].Contact.AccountID ))
                               ORDER BY createdDate desc]; //and Deposit_Transferred__c=false
            }
            else{
                depositList = [SELECT Id,Start_Date_Text__c,Deposit_Account_Number__c,Property_Address__c,Start_Date__c,Deposit_Amount__c,
                               Number_of_Tenants_Value__c,Property_Address_Without_Country__c,Protected_Amount__c, Actual_Protected_Amount__c,CreatedDate from Deposit__c 
                               WHERE Status__c=:depositStatus  and Customer__c =:currentUser[0].Contact.AccountID and Branch__c = NULL
                               ORDER BY createdDate desc]; //and Deposit_Transferred__c=false           
            }
        }
        else{
            depositList = [SELECT Id,Start_Date_Text__c,Deposit_Account_Number__c,Property_Address__c,Start_Date__c,Deposit_Amount__c,
                           Number_of_Tenants_Value__c,Property_Address_Without_Country__c,Protected_Amount__c, Actual_Protected_Amount__c,CreatedDate from Deposit__c 
                           where Branch__c =: branchid  and Status__c=:depositStatus order by createdDate desc];//and Deposit_Transferred__c=false
            
        }       
        //depositList = [SELECT Id,Deposit_Account_Number__c,Property_Address__c,Start_Date__c,Deposit_Amount__c,
        //Number_of_Tenants_Value__c from Deposit__c where Customer__c =:accountid and Status__c=:depositStatus];
        return depositList;
    }
    
    @AuraEnabled
    public static List<Deposit__c> getDepositRecordsBySearchText(String searchText,String branchid) {
        List<Deposit__c> depositList = new List<Deposit__c>();
        Set<Id> setDepositIds = new Set<Id>();
        List<Branch__c> branch = new List<Branch__c>();
        List<Deposit__c> depositListProperty = new List<Deposit__c>();
        Set<String> depositstatus = new Set<String>();
        
        String searchTextValue = '%' + String.escapeSingleQuotes(searchText.trim()) + '%';
        system.debug('++++++++++++searchTextValue++++++++'+searchTextValue);
         User currentUser = [Select Id, Email, ContactId,Contact.createdBy.Name ,AccountId,createdBy.Contact.AccountId,Contact.AccountId,Contact.Account.Parent_person_account__c from User where Id=:Userinfo.getUserId() LIMIT 1];
        
        Boolean additionalUser=false;
        if(currentUser.Contact.Account.Parent_person_account__c != NULL && currentUser.Contact.Account.Parent_person_account__c == currentUser.createdBy.Contact.AccountId){
            additionalUser = true;
        }
   
        for(Deposit_Status__mdt status : [SELECT Id,Label, DeveloperName, MasterLabel, NamespacePrefix from Deposit_Status__mdt ]){
            depositstatus.add(status.MasterLabel);
        }
        
        Id accountid = [Select id,Contact.AccountId from User where id=:Userinfo.getUserId()].Contact.AccountId;
        for(Deposit_Allocation__c depositAllocation : [SELECT Id,Deposit__c,Deposit__r.Property__r.Primary_Landlord__r.Name from Deposit_Allocation__c where Deposit__r.Customer__c = :accountid AND                                                
                        (Deposit_Holder__r.PersonEmail like:searchTextValue OR Deposit_Holder__r.Name like:searchTextValue OR 
                         Deposit_Holder__r.Phone like:searchTextValue OR Contact__r.Name like:searchTextValue OR 
                         Contact__r.Email  like:searchTextValue OR Deposit__r.Property__r.Primary_Landlord__r.Name Like :searchTextValue OR Contact__r.Phone  like:searchTextValue OR Contact__r.Name  like:searchTextValue 
                        /* OR Contact__r.Landlord_Registration_Number_Value__c  like:searchTextValue OR Deposit_Holder__r.Landlord_Registration_Number_Value__pc  like:searchTextValue*/)]){
            setDepositIds.add(depositAllocation.Deposit__c);                 
        }
        
        for(Property__c prop : [SELECT Id,(Select id from Deposits__r) FROM Property__c 
                                                        where Property_Owner__c =:currentUser.AccountId AND id in (Select Property__c from Property_Allocation__c  
                                                                     where Landlord_Registration_Number__c like:searchText)]){
            depositListProperty.addall(prop.Deposits__r);                 
        }       
        if(!depositListProperty.isEmpty()){
            for(Deposit__c deposit : depositListProperty){
                setDepositIds.add(deposit.Id);                
            }
        }
        /*for(Deposit_Allocation__c depositAllocation : [SELECT Id,Deposit__r.Deposit_Account_Number__c,Deposit__r.Property_Address__c,
                                                    Deposit__r.Start_Date__c,Deposit__r.Deposit_Amount__c,Deposit__r.Number_of_Tenants_Value__c 
                                                    from Deposit_Allocation__c where Contact__c IN (Select ContactId from User where MemberId__c like:searchTextValue) 
                                                    AND Deposit__r.Customer__c = :accountid]){
            setDepositIds.add(depositAllocation.Deposit__c);                 
        }
        for(Deposit_Allocation__c depositAllocation : [SELECT Id,Deposit__r.Deposit_Account_Number__c,Deposit__r.Property_Address__c,
                                                    Deposit__r.Start_Date__c,Deposit__r.Deposit_Amount__c,Deposit__r.Number_of_Tenants_Value__c 
                                                    from Deposit_Allocation__c where Deposit__r.Customer__c = :accountid AND
                                                    Deposit_Holder__c IN (Select AccountId from User where MemberId__c like:searchTextValue)]){
            setDepositIds.add(depositAllocation.Deposit__c);                 
        }*/
        
        if(branchid == null){
            branch =[Select id from Branch__c where id in (Select Branch__c from Branch_User_Mapping__c where User__c =: UserInfo.getUserId()) and Is_Active__c = true ORDER BY Branch_Name__c Limit 1];
            if(branch.size()>0){                
                
                for(Deposit__c deposit : [SELECT Id,Status__c,Property_Address_Without_Country__c,Start_Date_Text__c,Deposit_Account_Number__c,Property_Address__c,Start_Date__c,Deposit_Amount__c,Protected_Amount__c, Actual_Protected_Amount__c,Number_of_Tenants_Value__c from Deposit__c where ((Customer__c =:accountid and Branch__c = NULL) or (Branch__c =: branch[0].id and Customer__c =:accountid ))  AND (ID IN: setDepositIds OR Deposit_Account_Number__c like:searchTextValue OR Property_Address__c like:searchTextValue OR Property_Address_WO_Country__c like:searchTextValue OR Deposit_Amount_Value__c like:searchTextValue OR Protected_Amount_Value__c like:searchTextValue OR User_reference_for_the_deposit__c like :searchTextValue )]){ //and Deposit_Transferred__c=false
                    depositList.add(deposit);                
                }
            }
            else{
                if(additionalUser){
                    
                         for(Deposit__c deposit : [SELECT Id,Status__c,Property_Address_Without_Country__c,Start_Date_Text__c,Deposit_Account_Number__c,Property_Address__c,Start_Date__c,Deposit_Amount__c,Protected_Amount__c, Actual_Protected_Amount__c,Number_of_Tenants_Value__c from Deposit__c where (Customer__c =:currentUser.Contact.AccountId OR Customer__c =:currentUser.Contact.Account.Parent_person_account__c)  and Branch__c = NULL AND (ID IN: setDepositIds OR
                                    Deposit_Account_Number__c like:searchTextValue OR Property_Address__c like:searchTextValue OR Property_Address_WO_Country__c like:searchTextValue
                                     OR Deposit_Amount_Value__c like:searchTextValue OR Protected_Amount_Value__c like:searchTextValue OR User_reference_for_the_deposit__c like :searchTextValue)]){//and Deposit_Transferred__c=false
                        depositList.add(deposit);                
                    }
                }else{
                   //   List<Contact> conOther = [Select id from Contact where Account.Parent_person_account__c =: currentUser.accountId];
                 
                    for(Deposit__c deposit : [SELECT Id,Status__c,Property_Address_Without_Country__c,Start_Date_Text__c,Deposit_Account_Number__c,Property_Address__c,Start_Date__c,Deposit_Amount__c,Protected_Amount__c, Actual_Protected_Amount__c,Number_of_Tenants_Value__c from Deposit__c where (Customer__c =:currentUser.Contact.AccountId ) and Branch__c = NULL AND (ID IN: setDepositIds OR
                                    Deposit_Account_Number__c like:searchTextValue OR Property_Address__c like:searchTextValue OR Property_Address_WO_Country__c like:searchTextValue
                                     OR Deposit_Amount_Value__c like:searchTextValue OR Protected_Amount_Value__c like:searchTextValue OR  User_reference_for_the_deposit__c like :searchTextValue)]){//and Deposit_Transferred__c=false
                        depositList.add(deposit);                
                    }
                }
            }
        }
        else{
            for(Deposit__c deposit : [SELECT Id,Status__c,Property_Address_Without_Country__c,Start_Date_Text__c,Deposit_Account_Number__c,Property_Address__c,Start_Date__c,Deposit_Amount__c,Protected_Amount__c, Actual_Protected_Amount__c,Number_of_Tenants_Value__c  from Deposit__c where Branch__c =: branchid  AND 
                    (ID IN: setDepositIds OR Start_Date_Text__c like:searchTextValue OR Deposit_Account_Number__c like:searchTextValue OR Property_Address__c like:searchTextValue OR Property_Address_WO_Country__c like:searchTextValue OR Deposit_Amount_Value__c like:searchTextValue OR Protected_Amount_Value__c like:searchTextValue OR  User_reference_for_the_deposit__c like :searchTextValue)]){//and Deposit_Transferred__c=false
                depositList.add(deposit);                
            }
        }
        system.debug('++++++++++++depositList++++++++'+depositList);
        system.debug('++++++++++++depositList++++++++'+depositList.size());
        return depositList;
    }
    
}