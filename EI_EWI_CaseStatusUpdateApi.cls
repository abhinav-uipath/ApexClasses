public class EI_EWI_CaseStatusUpdateApi {
    public string clientUserName;
    public string clientPassword;
    public string headerKey;
    public string HeaderValue;
    public string verifyEndpoint;
    public string AccessTokenEndpoint;
    public string UpdateEndpoint;
    public string refreshAccessToken;
    public string CurrentValidAccessToken;
    public boolean isvalid;
    public EWI_Status_Update_API__c customsetting;
    public Case caseRecord;
    public string statusId;
    public string statusText;
    public string adjReportUrl;
    Public string tdsnNumber;
    Public string finalResponse;
    Public string depositDisputed;
    Public string depositReceived;
    Public string depositReceivedDate;
    Public string depositReceivedLate;
    Public string cleaningClaim;
    Public string damageClaim;
    Public string redecorationClaim;
    Public string gardeningClaim;
    Public string rentArrearsClaim;
    Public string otherClaim;
    Public string reportPublishedDate;
    Public string adjudicationQualityScore;
    Public string adjudicationComments;
    Public string awardTenant;
    Public string awardAgentLandlord;
    
    public string apiRequestBody;
    public Boolean justStatus;
    
    public EI_EWI_CaseStatusUpdateApi()
    {
        isvalid = true;
        justStatus = true;
        this.apiRequestBody ='';
        cleaningClaim ='0.00';
        damageClaim='0.00';
        redecorationClaim='0.00';
        gardeningClaim='0.00';
        rentArrearsClaim='0.00';
        otherClaim='0.00';
        depositReceivedLate='false';
        customsetting = [select id,AccessToken__c,Client_Password__c,Client_Username__c,
                         Header_Key__c,Header_Value__c,Live_Access_Token_URL__c,Live_URL__c,
                         LiveVerify_End_Point__c,Sandbox_Access_Token_URL__c,Sandbox_URL__c,
                         Sandbox_Verify_End_Point__c,Current_Access_Token__c	
                         from EWI_Status_Update_API__c];
        if(customsetting != null)
        {
            this.clientUserName = customsetting.Client_Username__c;
            this.clientPassword = customsetting.Client_Password__c;
            this.headerKey = customsetting.Header_Key__c;
            this.HeaderValue = customsetting.Header_Value__c;
            this.verifyEndpoint=runningInASandbox()? customsetting.Sandbox_Verify_End_Point__c:customsetting.LiveVerify_End_Point__c;
            this.AccessTokenEndpoint= runningInASandbox()? customsetting.Sandbox_Access_Token_URL__c:customsetting.Live_Access_Token_URL__c;
            this.UpdateEndpoint =runningInASandbox()? customsetting.Sandbox_URL__c:customsetting.Live_URL__c;
            this.refreshAccessToken= customsetting.AccessToken__c;
            this.CurrentValidAccessToken =customsetting.Current_Access_Token__c;
        }
        
    }
    @InvocableMethod (label='Perform Callout') 
    public static void PerformCallout(list<id> disputeID)
    {
        
        //initiateCallOut(disputeID);
        
    }
    
   // @future(callout=true)
    public static void PerformCalloutTrigger(list<id> disputeID)
    {
        for(id dis:disputeID )
        {
            list<id> ids = new list<id>();
            ids.add(dis);
            initiateCallOut(ids);
            ids.clear();
        }
    }
    
    public static void PerformCalloutMethod(list<id> disputeID)
    {
        for(id dis:disputeID )
        {
            list<id> ids = new list<id>();
            ids.add(dis);
            System.enqueueJob(new EI_EWI_Queueable_StatusUpdate(ids));
           // initiateCallOut(ids);
            ids.clear();
        }
    }
    
    @future(callout=true)
    public static void initiateCallOut(List<id> DisputeRecID)
    {
        
        Dispute_API_Error_Log__c disputelog = new Dispute_API_Error_Log__c();
        disputelog.API_Name__c ='Status Update API';
        
        EI_EWI_CaseStatusUpdateApi ewi = new EI_EWI_CaseStatusUpdateApi();
        ewi.caseRecord = [select id,V_External_Id__c,status,Deposit_Account_Number__r.Depository__c,
                          Disputed_Funds_Received__c,No_Landlord_Evidence__c,No_Tenant_Evidence__c,
                          (select id,Webhook_Report_Link__c,Adjudicators_score__c,Published_Date__c,
                           Awarded_to_Tenant__c,Amount_to_Agent_Landlord__c
                           from Adjudication_Reports__r
                           where Status__c='Published' order by Published_Date__c desc limit 1)
                          from case where id=:DisputeRecID[0] ];
        ewi.tdsnNumber = ewi.caseRecord.V_External_Id__c;
        ewi.getStatusIdandText(ewi.caseRecord);
        
        try{
            if(!ewi.ValidateAccessCode())
            {
                ewi.CurrentValidAccessToken =ewi.GenrateAccessCode();
            }
            ewi.calloutToVplus();
            if(ewi.CurrentValidAccessToken != ewi.customsetting.Current_Access_Token__c)
            {
                EWI_Status_Update_API__c setting = new EWI_Status_Update_API__c(id =ewi.customsetting.id,Current_Access_Token__c=ewi.CurrentValidAccessToken);
                update setting;
            }
            disputelog.JSON_request__c= String.valueOf(ewi.caseRecord)+'------------'+ewi.apiRequestBody;
            disputelog.JSON_response__c = ewi.finalResponse;
            insert disputelog;
            
        }
        catch(FC_DisputeAPI_Exception exc) {
            disputelog.JSON_response__c = JSON.serialize(exc.getMessage());
            insert disputelog;
        }
        
    }
    //@future(callout=true)
    public  Boolean ValidateAccessCode() {
        String endpoint;
        Map<String, String> apiResult = new Map<String, String>();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        endpoint = verifyEndpoint;
        req.setEndpoint(Endpoint);
        req.setMethod('POST');
        String OldAccesToken = 'Bearer '+CurrentValidAccessToken;
        // Setting Header
        req.setHeader('Authorization', OldAccesToken);
        req.setHeader(headerKey, HeaderValue);
        res = http.send(req);
        Map<String, Object> ResponseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        return boolean.valueOf(ResponseMap.get('success'));
        
        
    }
    public string GenrateAccessCode() {
        
        String endpoint;
        string Returnvalue='';
        Map<String, String> apiResult = new Map<String, String>();
        
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        endpoint = AccessTokenEndpoint;
        req.setEndpoint(Endpoint);
        req.setMethod('POST');
        
        // Setting Authorization
        String username = clientUserName;
        String password = clientPassword;
        Blob headerAuthorization = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerAuthorization);
        req.setHeader('Authorization', authorizationHeader);
        
        // Setting Header
        req.setHeader(headerKey, HeaderValue);
        
        // Setting Body
        String grantType = 'refresh_token';
        String token = refreshAccessToken;
        req.setHeader('Content-Type','multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');
        req.setbody('------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"grant_type\"\r\n\r\n'+grantType+'\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"refresh_token\"\r\n\r\n'
                    +token+'\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW--');
        if (!Test.isRunningTest()) { 
            res = http.send(req);
            
            if(res.getstatusCode() == 200 && res.getbody() != null) { 
                Map<String, Object> ResponseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                Returnvalue = string.valueOf(ResponseMap.get('access_token'));
                
            } else {
            }
        }
        return Returnvalue;
    }
    public  string calloutToVplus() {
        String endpoint;
        string Returnvalue='';
        String token = CurrentValidAccessToken;
        String disputeId = tdsnNumber;
        string stageId =statusId;
        string stageName =statusText;
        String ReportUrl =adjReportUrl;
        Map<String, String> apiResult = new Map<String, String>();      
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        endpoint = UpdateEndpoint+disputeId;
        req.setEndpoint(Endpoint);
        req.setMethod('POST');
        // Setting Header
        req.setHeader(headerKey, HeaderValue);
        String AccesToken = 'Bearer '+token;
        req.setHeader('Authorization', AccesToken);
        
        
        
        // Setting Body
        req.setHeader('Content-Type','multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');
        
        if(justStatus)
        {
            string caseStatus =(String.valueOf(caseRecord.Status).replace('–','-'));
            req.setbody('------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"stage_text\"\r\n\r\n'+caseStatus+'\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW--');
            
        }
        else
        {
            req.setbody('------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"stage_text\"\r\n\r\n'+'Deposit to be repaid - decision issued'+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"deposit_disputed\"\r\n\r\n'+depositDisputed+ 
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\" deposit_received\"\r\n\r\n'+depositReceived+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"deposit_received_date\"\r\n\r\n'+depositReceivedDate+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"deposit_received_late\"\r\n\r\n'+depositReceivedLate+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"cleaning_claim\"\r\n\r\n'+cleaningClaim+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"damage_claim\"\r\n\r\n'+damageClaim+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"redecoration_claim\"\r\n\r\n'+redecorationClaim+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"gardening_claim\"\r\n\r\n'+gardeningClaim+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"rent_arrears_claim\"\r\n\r\n'+rentArrearsClaim+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"other_claim\"\r\n\r\n'+otherClaim+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"report_published_date\"\r\n\r\n'+reportPublishedDate+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"report_url\"\r\n\r\n'+adjReportUrl+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"adjudication_quality_score\"\r\n\r\n'+adjudicationQualityScore+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"adjudication_comments\"\r\n\r\n'+adjudicationComments+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"award_tenant\"\r\n\r\n'+awardTenant+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"award_agent\"\r\n\r\n'+awardAgentLandlord+
                        '\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW--');
            
        }
        
        
        apiRequestBody = string.valueOf(req.getBody());
        res = http.send(req);
        
        if(res.getstatusCode() == 200 && res.getbody() != null) { 
            Map<String, Object> ResponseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            //  Returnvalue = string.valueOf(ResponseMap.get('access_token'));
            finalResponse = string.valueOf(ResponseMap);
        } else {
            finalResponse = string.valueOf(res.getBody());
        }
        
        return null;
    }
    public static Boolean runningInASandbox() {
        return [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
    public void getStatusIdandText(case caseRecord)
    {
        if(caseRecord.status=='Deposit to be repaid - decision issued' || caseRecord.status=='Deposit to be repaid – decision issued')
        {
            list<Adjudication_Report_Item__c> adjReport = [select id,Type__c,Claimed_Amount__c,Disputed_Amount__c,Adjudication_Report__r.Disputed_Amount__c,
                                                           Adjudication_Report__r.Published_Date__c,Adjudication_Report__r.Adjudicators_score__c,Adjudication_Report__r.Adjudication_Score_for_V__c,
                                                           Adjudication_Report__r.Awarded_to_Tenant__c,Adjudication_Report__r.Amount_to_Agent_Landlord__c,
                                                           Adjudication_Report__r.Webhook_Report_Link__c,Adjudication_Report__r.Statement__c,
                                                           Adjudication_Report__r.Dispute__r.Amount_of_Disputed_Funds_Received__c,
                                                           Adjudication_Report__r.Dispute__r.Amount_of_Disputed_Funds_Required__c,
                                                           Adjudication_Report__r.Dispute__r.Date_Disputed_Funds_Received__c,
                                                           Adjudication_Report__r.Dispute__r.Evidence_Review_Complete_Date__c
                                                           from Adjudication_Report_Item__c where Adjudication_Report__r.Dispute__c =:caseRecord.id
                                                           and Adjudication_Report__r.Status__c='Published' order by Adjudication_Report__r.Published_Date__c];
            
            justStatus = false;
            //statusText=String.valueOf(caseRecord.status).trim();
            /*adjReportUrl = caseRecord.Adjudication_Reports__r[0].Webhook_Report_Link__c;
adjudicationQualityScore =caseRecord.Adjudication_Reports__r[0].Adjudicators_score__c ;
awardTenant = string.valueOf(caseRecord.Adjudication_Reports__r[0].Awarded_to_Tenant__c);
awardAgentLandlord = string.valueOf(caseRecord.Adjudication_Reports__r[0].Amount_to_Agent_Landlord__c);
*/
            depositDisputed = string.valueOf(adjReport[0].Adjudication_Report__r.Dispute__r.Amount_of_Disputed_Funds_Required__c); 
            depositReceived = string.valueOf(adjReport[0].Adjudication_Report__r.Dispute__r.Amount_of_Disputed_Funds_Received__c);
            depositReceivedDate=adjReport[0].Adjudication_Report__r.Dispute__r.Date_Disputed_Funds_Received__c ==null?'':string.valueOf((adjReport[0].Adjudication_Report__r.Dispute__r.Date_Disputed_Funds_Received__c).format());
            if(adjReport[0].Adjudication_Report__r.Dispute__r.Date_Disputed_Funds_Received__c > adjReport[0].Adjudication_Report__r.Dispute__r.Evidence_Review_Complete_Date__c)
            {
               depositReceivedLate='true'; 
            }
            
            for(Adjudication_Report_Item__c adr:adjReport )
            {
                if(adr.Type__c == 'Cleaning')
                {
                    cleaningClaim =string.valueOf(adr.Disputed_Amount__c);   
                }
                if(adr.Type__c == 'Damage')
                {
                    damageClaim =string.valueOf(adr.Disputed_Amount__c);  
                }
                if(adr.Type__c == 'Redecoration')
                {
                    redecorationClaim =string.valueOf(adr.Disputed_Amount__c); 
                }
                if(adr.Type__c == 'Gardening')
                {
                    gardeningClaim =string.valueOf(adr.Disputed_Amount__c); 
                }
                if(adr.Type__c == 'Rent')
                {
                    rentArrearsClaim = string.valueOf(adr.Disputed_Amount__c); 
                }
                if(adr.Type__c == 'Other')
                {
                    otherClaim = string.valueOf(adr.Disputed_Amount__c);  
                }
                
            }
            reportPublishedDate = string.valueOf((adjReport[0].Adjudication_Report__r.Published_Date__c.Date()).format());
            adjReportUrl = string.valueOf(adjReport[0].Adjudication_Report__r.Webhook_Report_Link__c);
            adjudicationQualityScore =adjReport[0].Adjudication_Report__r.Adjudicators_score__c==null?'': string.valueOf(adjReport[0].Adjudication_Report__r.Adjudication_Score_for_V__c);
            adjudicationComments = string.valueOf(adjReport[0].Adjudication_Report__r.Statement__c);
            awardTenant = string.valueOf(adjReport[0].Adjudication_Report__r.Awarded_to_Tenant__c); 
            awardAgentLandlord = string.valueOf(adjReport[0].Adjudication_Report__r.Amount_to_Agent_Landlord__c);
            
            
            
        }
        else
        {
            justStatus=true;
            //statusText=String.valueOf(caseRecord.status).trim();
            
        }
        
    }
    
}