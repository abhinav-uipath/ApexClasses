({
    
    serverCallHelper : function(component, apexAction, params ) {
        
        var p = new Promise( $A.getCallback( function( resolve , reject ) {
            var action = component.get("c."+apexAction+"");
            action.setParams( params );
            action.setCallback( this , function(callbackResult) {
                if(callbackResult.getState()=='SUCCESS') {
                    resolve( callbackResult.getReturnValue() );
                }
                if(callbackResult.getState()=='ERROR') {
                    console.log('Error message: ', callbackResult.getError() ); 
                    reject( callbackResult.getError() );
                }
            });
            $A.enqueueAction(action);
        }));            
        return p;
        
    },
    
	/* Getting all deposit statuses */    
    getAllDeposits : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var allDepositStatusesList;
        
        var action = component.get("c.getAllDeposits");
        action.setParams({branchid : branchid});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                console.log("From server: " + response.getReturnValue());
                
				allDepositStatusesList = response.getReturnValue();
                component.set("v.allDepositsList", allDepositStatusesList);
                console.log('Line 136 weird123 -> '+JSON.stringify(allDepositStatusesList));
                console.log('Line 137 weird123 -> '+allDepositStatusesList.length);
                
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
        console.log('Line 158 ttyl -> '+allDepositStatusesList);
        
    },
        
    /* Get Deposits by Status */
    getDepositsByStatuses : function(component, allDeposits) {
        
        var registeredNotPaidNumber =0 , awaitingRecieptOfDepositNumber = 0, depositHeldBySafedepositNumber = 0, repaymentbyTenantNumber = 0;
        var repaymentbyAgentLandlordNumber = 0, selfResolutionNumber = 0, inDisputeResolutionNumber =0 , paymentApproveNumber = 0, depositLastYearNumber = 0;
        var registeredNotPaidAmount =0.00, awaitingRecieptOfDepositAmount = 0.00, depositHeldBySafedepositAmount = 0.00, repaymentbyTenantAmount = 0.00;
        var repaymentbyAgentLandlordAmount = 0.00, selfResolutionAmount=0.00, inDisputeResolutionAmount =0.00, paymentApproveAmount = 0.00, depositLastYearAmount = 0.00;
        
        var registeredNotPaidList = [];
        var awaitingPaymentList = [];
        var heldBySafeDepositList = [];
        var repaymentRequestedTenantList = [];
        var repaymentRequestedAgentLandlordList = [];
        var selfResolutionList = [];
        var inDisputeResolutionList = [];
        var paymentApprovedList = [];
        var depositRepaymentLastYearList = [];
        
     //   console.log('Call 72 weird123 : ',JSON.stringify(allDeposits));
        //debugger;
        for(var i=0; i<allDeposits.length; i++) {
            
       //     console.log('Call 76 weird123 : ',allDeposits[i].Status__c);
            
            if(allDeposits[i].Status__c == 'Registered (not paid)') {
                registeredNotPaidNumber = registeredNotPaidNumber + 1 ;
                registeredNotPaidAmount = allDeposits[i].Deposit_Amount__c +  registeredNotPaidAmount;
                registeredNotPaidList.push(allDeposits[i]);
                
            } else if(allDeposits[i].Status__c == 'Awaiting payment') {
                awaitingRecieptOfDepositNumber = awaitingRecieptOfDepositNumber + 1;
                awaitingRecieptOfDepositAmount = allDeposits[i].Protected_Amount__c +  awaitingRecieptOfDepositAmount;
                awaitingPaymentList.push(allDeposits[i]);
                
            } else if(allDeposits[i].Status__c == 'Deposits held by scheme') {
                depositHeldBySafedepositNumber = depositHeldBySafedepositNumber + 1;
                depositHeldBySafedepositAmount = allDeposits[i].Actual_Protected_Amount__c +  depositHeldBySafedepositAmount;
                heldBySafeDepositList.push(allDeposits[i]);
                
            } else if(allDeposits[i].Status__c == 'Repayment requested by tenant') {
                repaymentbyTenantNumber = repaymentbyTenantNumber + 1;
                repaymentbyTenantAmount = allDeposits[i].Protected_Amount__c +  repaymentbyTenantAmount;
                repaymentRequestedTenantList.push(allDeposits[i]);
                
            } else if(allDeposits[i].Status__c == 'Repayment requested by agent/landlord') {
                repaymentbyAgentLandlordNumber = repaymentbyAgentLandlordNumber + 1;
                repaymentbyAgentLandlordAmount = allDeposits[i].Protected_Amount__c +  repaymentbyAgentLandlordAmount;
                repaymentRequestedAgentLandlordList.push(allDeposits[i]);
                
            } else if(allDeposits[i].Status__c == 'Repayment not agreed - In self-resolution') {
                selfResolutionNumber = selfResolutionNumber + 1;
                selfResolutionAmount = allDeposits[i].Protected_Amount__c +  selfResolutionAmount;
                selfResolutionList.push(allDeposits[i]);
                
            } else if(allDeposits[i].Status__c == 'Repayment not agreed - In dispute resolution') {
                inDisputeResolutionNumber = inDisputeResolutionNumber + 1;
                inDisputeResolutionAmount = allDeposits[i].Protected_Amount__c +  inDisputeResolutionAmount;
                inDisputeResolutionList.push(allDeposits[i]);
                
            } else if(allDeposits[i].Status__c == 'Repayment process') {
                paymentApproveNumber = paymentApproveNumber + 1;
                paymentApproveAmount = allDeposits[i].Protected_Amount__c +  paymentApproveAmount;
                paymentApprovedList.push(allDeposits[i]);
                
            } else if(allDeposits[i].Status__c == 'Deposits repayments concluded in the last year') {
                depositLastYearNumber = depositLastYearNumber + 1;
                depositLastYearAmount = allDeposits[i].Protected_Amount__c +  depositLastYearAmount;
                depositRepaymentLastYearList.push(allDeposits[i]);
            }
            
        }
        
        component.set("v.registeredNotPaidNumber", registeredNotPaidNumber);
        component.set("v.registeredNotPaidAmount", registeredNotPaidAmount.toFixed(2));
        component.set("v.registeredNotPaidRecords", registeredNotPaidList);
        // Pagination for Registered (not paid)
        if(registeredNotPaidList.length>0) {
            var pageSize = component.get("v.pageSizeRNP");
            var totalRecordsList = registeredNotPaidList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountRNP", totalLength);
            component.set("v.startPageRNP", 0);
            component.set("v.endPageRNP", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListRNP", PaginationList);
            component.set("v.totalPagesCountRNP", Math.ceil(totalLength / pageSize));
        }
        
        component.set("v.paymentSentToSafeDepositNumber", awaitingRecieptOfDepositNumber);
        component.set("v.paymentSentToSafeDepositAmount", awaitingRecieptOfDepositAmount.toFixed(2));
        component.set("v.paymentSentToSafeDepositRecords", awaitingPaymentList);
        // Pagination for Awaiting payment
        if(awaitingPaymentList.length>0) {
            var pageSize = component.get("v.pageSizeAP");
            var totalRecordsList = awaitingPaymentList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountAP", totalLength);
            component.set("v.startPageAP", 0);
            component.set("v.endPageAP", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListAP", PaginationList);
            component.set("v.totalPagesCountAP", Math.ceil(totalLength / pageSize));
        }
        
        component.set("v.heldBySafeDepositNumber", depositHeldBySafedepositNumber);
        component.set("v.heldBySafeDepositAmount", depositHeldBySafedepositAmount.toFixed(2));
        component.set("v.heldBySafeDepositRecords", heldBySafeDepositList);
        // Pagination for Deposits held by scheme
        if(heldBySafeDepositList.length>0) {
            var pageSize = component.get("v.pageSizeDHBS");
            var totalRecordsList = heldBySafeDepositList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountDHBS", totalLength);
            component.set("v.startPageDHBS", 0);
            component.set("v.endPageDHBS", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListDHBS", PaginationList);
            component.set("v.totalPagesCountDHBS", Math.ceil(totalLength / pageSize));
        }
        
        component.set("v.repaymentRequestedTenantNumber", repaymentbyTenantNumber);
        component.set("v.repaymentRequestedTenantAmount", repaymentbyTenantAmount.toFixed(2));
        component.set("v.repaymentRequestedTenantRecords", repaymentRequestedTenantList);
        // Pagination for Repayment requested by tenant
        if(repaymentRequestedTenantList.length>0) {
            var pageSize = component.get("v.pageSizeRRbyTenant");
            var totalRecordsList = repaymentRequestedTenantList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountRRbyTenant", totalLength);
            component.set("v.startPageRRbyTenant", 0);
            component.set("v.endPageRRbyTenant", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListRRbyTenant", PaginationList);
            component.set("v.totalPagesCountRRbyTenant", Math.ceil(totalLength / pageSize));
        }
        
        component.set("v.repaymentRequestedAgentLandlordNumber", repaymentbyAgentLandlordNumber);
        component.set("v.repaymentRequestedAgentLandlordAmount", repaymentbyAgentLandlordAmount.toFixed(2));
        component.set("v.repaymentRequestedAgentLandlordRecords", repaymentRequestedAgentLandlordList);
        // Pagination for Repayment requested by agent/landlord
        if(repaymentRequestedAgentLandlordList.length>0) {
            var pageSize = component.get("v.pageSizeRRbyAGLL");
            var totalRecordsList = repaymentRequestedAgentLandlordList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountRRbyAGLL", totalLength);
            component.set("v.startPageRRbyAGLL", 0);
            component.set("v.endPageRRbyAGLL", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListRRbyAGLL", PaginationList);
            component.set("v.totalPagesCountRRbyAGLL", Math.ceil(totalLength / pageSize));
        }
        
        component.set("v.selfResolutionNumber", selfResolutionNumber);
        component.set("v.selfResolutionAmount", selfResolutionAmount.toFixed(2));
        component.set("v.selfResolutionRecords", selfResolutionList);
        // Pagination for Repayment not agreed - In self-resolution
        if(selfResolutionList.length>0) {
            var pageSize = component.get("v.pageSizeRnotAgrdSR");
            var totalRecordsList = selfResolutionList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountRnotAgrdSR", totalLength);
            component.set("v.startPageRnotAgrdSR", 0);
            component.set("v.endPageRnotAgrdSR", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListRnotAgrdSR", PaginationList);
            component.set("v.totalPagesCountRnotAgrdSR", Math.ceil(totalLength / pageSize));
        }
        
        component.set("v.inDisputeResolutionNumber", inDisputeResolutionNumber);
        component.set("v.inDisputeResolutionAmount", inDisputeResolutionAmount.toFixed(2));
        component.set("v.inDisputeResolutionRecords", inDisputeResolutionList);
        // Pagination for Repayment not agreed - In dispute resolution
        if(inDisputeResolutionList.length>0) {
            var pageSize = component.get("v.pageSizeRnotAgrdDR");
            var totalRecordsList = inDisputeResolutionList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountRnotAgrdDR", totalLength);
            component.set("v.startPageRnotAgrdDR", 0);
            component.set("v.endPageRnotAgrdDR", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListRnotAgrdDR", PaginationList);
            component.set("v.totalPagesCountRnotAgrdDR", Math.ceil(totalLength / pageSize));
        }
        
        component.set("v.paymentApprovedNumber", paymentApproveNumber);
        component.set("v.paymentApprovedAmount", paymentApproveAmount.toFixed(2));
        component.set("v.paymentApprovedRecords", paymentApprovedList);
        // Pagination for Repayment process
        if(paymentApprovedList.length>0) {
            var pageSize = component.get("v.pageSizeRP");
            var totalRecordsList = paymentApprovedList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountRP", totalLength);
            component.set("v.startPageRP", 0);
            component.set("v.endPageRP", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListRP", PaginationList);
            component.set("v.totalPagesCountRP", Math.ceil(totalLength / pageSize));
        }
        
        component.set("v.depositRepaymentNumber", depositLastYearNumber);
        component.set("v.depositRepaymentAmount", depositLastYearAmount.toFixed(2));
        component.set("v.depositRepaymentRecords", depositRepaymentLastYearList);
        // Pagination for Deposit repayments concluded in the last year
        if(depositRepaymentLastYearList.length>0) {
            var pageSize = component.get("v.pageSizeDRCLY");
            var totalRecordsList = depositRepaymentLastYearList;
            var totalLength = totalRecordsList.length;
            component.set("v.totalRecordsCountDRCLY", totalLength);
            component.set("v.startPageDRCLY", 0);
            component.set("v.endPageDRCLY", pageSize - 1);
            var PaginationList = [];
            for (var i = 0; i < pageSize; i++) {
                if (totalRecordsList.length > i) {
                    PaginationList.push(totalRecordsList[i]);
                }
            }
            component.set("v.paginationListDRCLY", PaginationList);
            component.set("v.totalPagesCountDRCLY", Math.ceil(totalLength / pageSize));
        }
        
    },
    
    /*
    getDeposits : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        component.set("v.branchid",branchid);
        
        var action = component.get("c.getDeposit");
        
        action.setParams({branchid : branchid});
        var registeredNotPaidNumber =0 , awaitingRecieptOfDepositNumber = 0, depositHeldBySafedepositNumber = 0, repaymentbyTenantNumber = 0;
        var registeredNotPaidAmount =0.00, awaitingRecieptOfDepositAmount = 0.00, depositHeldBySafedepositAmount = 0.00, repaymentbyTenantAmount = 0.00;
        var repaymentbyAgentLandlordNumber = 0,selfResolutionNumber = 0, inDisputeResolutionNumber =0 , paymentApproveNumber = 0, depositLastYearNumber = 0;
        var repaymentbyAgentLandlordAmount = 0.00,selfResolutionAmount=0.00 ,inDisputeResolutionAmount =0.00, paymentApproveAmount = 0.00, depositLastYearAmount = 0.00;
        action.setCallback(this, function(response) {
            
            var allValues = response.getReturnValue();
            console.log('allValues -- >> ' + allValues);
            if(allValues!=null) {
                console.log('allValues1111 -- >> ');
                console.log('allValues1111 -- >> ' + JSON.stringify(allValues));
                for(var i = 0; i < allValues.length; i++) {
                    console.log('allValues -- >> ' +  allValues[i].Status__c);
                    if(allValues[i].Status__c==$A.get("$Label.c.Registered_not_paid")){
                        registeredNotPaidNumber = registeredNotPaidNumber + 1 ;
                        registeredNotPaidAmount = allValues[i].Deposit_Amount__c +  registeredNotPaidAmount;
                        component.set("v.registeredNotPaidNumber", registeredNotPaidNumber);
                        component.set("v.registeredNotPaidAmount", registeredNotPaidAmount.toFixed(2));
                        console.log('allValues -- >> ' +  allValues[i].Deposit_Amount__c);
                    }
                }
                for(var i = 0; i < allValues.length; i++){
                    if(allValues[i].Status__c==$A.get("$Label.c.Awaiting_receipt_of_deposit")){
                        awaitingRecieptOfDepositNumber = awaitingRecieptOfDepositNumber + 1;
                        awaitingRecieptOfDepositAmount = allValues[i].Protected_Amount__c +  awaitingRecieptOfDepositAmount;
                        
                        component.set("v.paymentSentToSafeDepositNumber", awaitingRecieptOfDepositNumber);
                        component.set("v.paymentSentToSafeDepositAmount", awaitingRecieptOfDepositAmount.toFixed(2));
                    }
                }
                for(var i = 0; i < allValues.length; i++){
                    console.log('allValues[i].Status__c -- >> ' +  allValues[i].Status__c);
                    console.log('allValues -- >> ' +  $A.get("$Label.c.Deposits_held_by_SafeDeposits_Scotland"));
                    if(allValues[i].Status__c==$A.get("$Label.c.Deposits_held_by_SafeDeposits_Scotland")){
                        depositHeldBySafedepositNumber = depositHeldBySafedepositNumber + 1;
                        depositHeldBySafedepositAmount = allValues[i].Deposit_Amount__c +  depositHeldBySafedepositAmount;
                        component.set("v.heldBySafeDepositNumber", depositHeldBySafedepositNumber);
                        component.set("v.heldBySafeDepositAmount", depositHeldBySafedepositAmount.toFixed(2));
                    }
                }
                for(var i = 0; i < allValues.length; i++){
                    if(allValues[i].Status__c==$A.get("$Label.c.Repayment_requested_by_tenant")){
                        repaymentbyTenantNumber = repaymentbyTenantNumber + 1;
                        repaymentbyTenantAmount = allValues[i].Deposit_Amount__c +  repaymentbyTenantAmount;
                        component.set("v.repaymentRequestedTenantNumber", repaymentbyTenantNumber);
                        component.set("v.repaymentRequestedTenantAmount", repaymentbyTenantAmount.toFixed(2));
                    }
                }
                for(var i = 0; i < allValues.length; i++){
                    if(allValues[i].Status__c==$A.get("$Label.c.Repayment_requested_by_agent_landlord")){
                        repaymentbyAgentLandlordNumber = repaymentbyAgentLandlordNumber + 1;
                        repaymentbyAgentLandlordAmount = allValues[i].Deposit_Amount__c +  repaymentbyAgentLandlordAmount;
                        component.set("v.repaymentRequestedAgentLandlordNumber", repaymentbyAgentLandlordNumber);
                        component.set("v.repaymentRequestedAgentLandlordAmount", repaymentbyAgentLandlordAmount.toFixed(2));
                    }
                }
                for(var i = 0; i < allValues.length; i++){
                    if(allValues[i].Status__c==$A.get("$Label.c.Self_resolution")){
                        selfResolutionNumber = selfResolutionNumber + 1;
                        selfResolutionAmount = allValues[i].Deposit_Amount__c +  selfResolutionAmount;
                        component.set("v.selfResolutionNumber", selfResolutionNumber);
                        component.set("v.selfResolutionAmount", selfResolutionAmount.toFixed(2));
                    }
                }
                for(var i = 0; i < allValues.length; i++){
                    if(allValues[i].Status__c==$A.get("$Label.c.In_dispute_resolution")){
                        inDisputeResolutionNumber = inDisputeResolutionNumber + 1;
                        inDisputeResolutionAmount = allValues[i].Deposit_Amount__c +  inDisputeResolutionAmount;
                        component.set("v.inDisputeResolutionNumber", inDisputeResolutionNumber);
                        component.set("v.inDisputeResolutionAmount", inDisputeResolutionAmount.toFixed(2));
                    }
                }
                for(var i = 0; i < allValues.length; i++){
                    if(allValues[i].Status__c==$A.get("$Label.c.Repayment_process")){
                        paymentApproveNumber = paymentApproveNumber + 1;
                        paymentApproveAmount = allValues[i].Deposit_Amount__c +  paymentApproveAmount;
                        component.set("v.paymentApprovedNumber", paymentApproveNumber);
                        component.set("v.paymentApprovedAmount", paymentApproveAmount.toFixed(2));
                    }
                }
                for(var i = 0; i < allValues.length; i++){
                    if(allValues[i].Status__c==$A.get("$Label.c.Deposits_repaid_in_the_last_year")){
                        depositLastYearNumber = depositLastYearNumber + 1;
                        depositLastYearAmount = allValues[i].Deposit_Amount__c +  depositLastYearAmount;
                        component.set("v.depositRepaymentNumber", depositLastYearNumber);
                        component.set("v.depositRepaymentAmount", depositLastYearAmount.toFixed(2));
                    }
                }
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Registered (not paid) 
    getDepositsRegisteredNotpaid : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : $A.get("$Label.c.Registered_not_paid"),branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
                console.log('allValues display2222222222222-- >> ' + allValues);
                component.set("v.registeredNotPaidRecords", allValues);
                console.log('Line 132 weird -> '+JSON.stringify(component.get("v.registeredNotPaidRecords")));
                // Pagination
                var pageSize = component.get("v.pageSizeRNP");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountRNP", totalLength);
                component.set("v.startPageRNP", 0);
                component.set("v.endPageRNP", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListRNP", PaginationList);
                component.set("v.totalPagesCountRNP", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Awaiting payment 
    getPaymentsSentSafeDeposits : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : $A.get("$Label.c.Awaiting_receipt_of_deposit"),branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
                //console.log('allValues display-- >> ' + allValues);
                component.set("v.paymentSentToSafeDepositRecords", allValues);
                console.log('Line 163 weird -> '+component.get("v.paymentSentToSafeDepositRecords").length);
                console.log('Line 164 weird -> '+JSON.stringify(component.get("v.paymentSentToSafeDepositRecords")));
                // Pagination
                var pageSize = component.get("v.pageSizeAP");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountAP", totalLength);
                component.set("v.startPageAP", 0);
                component.set("v.endPageAP", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListAP", PaginationList);
                component.set("v.totalPagesCountAP", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Deposits held by scheme 
    getPaymentsHeldSafeDeposits : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : $A.get("$Label.c.Deposits_held_by_SafeDeposits_Scotland"),branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
              //  console.log('allValues display-- >> ' + allValues);
                component.set("v.heldBySafeDepositRecords", allValues);
                console.log('Line 195 weird -> '+component.get("v.heldBySafeDepositRecords").length);
                console.log('Line 196 weird -> '+JSON.stringify(component.get("v.heldBySafeDepositRecords")));
                // Pagination
                var pageSize = component.get("v.pageSizeDHBS");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountDHBS", totalLength);
                component.set("v.startPageDHBS", 0);
                component.set("v.endPageDHBS", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListDHBS", PaginationList);
                component.set("v.totalPagesCountDHBS", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Repayment requested by tenant 
    getRepaymentsRequestedTenants : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : $A.get("$Label.c.Repayment_requested_by_tenant"),branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
          //      console.log('allValues display-- >> ' + allValues);
                component.set("v.repaymentRequestedTenantRecords", allValues);
                // Pagination
                var pageSize = component.get("v.pageSizeRRbyTenant");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountRRbyTenant", totalLength);
                component.set("v.startPageRRbyTenant", 0);
                component.set("v.endPageRRbyTenant", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListRRbyTenant", PaginationList);
                component.set("v.totalPagesCountRRbyTenant", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Repayment requested by agent/landlord 
    getRepaymentsRequestedAgentLandlord : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : 'Repayment requested by agent/landlord',branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
            //    console.log('allValues display-- >> ' + allValues);
                component.set("v.repaymentRequestedAgentLandlordRecords", allValues);
                // Pagination
                var pageSize = component.get("v.pageSizeRRbyAGLL");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountRRbyAGLL", totalLength);
                component.set("v.startPageRRbyAGLL", 0);
                component.set("v.endPageRRbyAGLL", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListRRbyAGLL", PaginationList);
                component.set("v.totalPagesCountRRbyAGLL", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Repayment not agreed - In self-resolution 
    getSelfResolutionResolution : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : $A.get("$Label.c.Self_resolution"),branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
           //     console.log('allValues display-- >> ' + allValues);
                component.set("v.selfResolutionRecords", allValues);
                // Pagination
                var pageSize = component.get("v.pageSizeRnotAgrdSR");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountRnotAgrdSR", totalLength);
                component.set("v.startPageRnotAgrdSR", 0);
                component.set("v.endPageRnotAgrdSR", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListRnotAgrdSR", PaginationList);
                component.set("v.totalPagesCountRnotAgrdSR", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Repayment not agreed - In dispute resolution 
    getInDisputeResolution : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : $A.get("$Label.c.In_dispute_resolution"),branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
           //     console.log('allValues display-- >> ' + allValues);
                component.set("v.inDisputeResolutionRecords", allValues);
                // Pagination
                var pageSize = component.get("v.pageSizeRnotAgrdDR");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountRnotAgrdDR", totalLength);
                component.set("v.startPageRnotAgrdDR", 0);
                component.set("v.endPageRnotAgrdDR", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListRnotAgrdDR", PaginationList);
                component.set("v.totalPagesCountRnotAgrdDR", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Repayment process 
    getPaymentApproved : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : $A.get("$Label.c.Repayment_process"),branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
            //    console.log('allValues display-- >> ' + allValues);
                component.set("v.paymentApprovedRecords", allValues);
                // Pagination
                var pageSize = component.get("v.pageSizeRP");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountRP", totalLength);
                component.set("v.startPageRP", 0);
                component.set("v.endPageRP", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListRP", PaginationList);
                component.set("v.totalPagesCountRP", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Deposits repayments concluded in the last year 
    getDepositRepaymentLastMonth : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositsByStatus");
        action.setParams({status : $A.get("$Label.c.Deposits_repaid_in_the_last_year"),branchid : branchid});
        action.setCallback(this, function(response) {
            var allValues = response.getReturnValue();
            if(allValues!=null){
            //    console.log('allValues display-- >> ' + allValues);
                component.set("v.depositRepaymentRecords", allValues);
                // Pagination
                var pageSize = component.get("v.pageSizeDRCLY");
                var totalRecordsList = allValues;
                var totalLength = totalRecordsList.length;
                component.set("v.totalRecordsCountDRCLY", totalLength);
                component.set("v.startPageDRCLY", 0);
                component.set("v.endPageDRCLY", pageSize - 1);
                var PaginationList = [];
                for (var i = 0; i < pageSize; i++) {
                    if (totalRecordsList.length > i) {
                        PaginationList.push(totalRecordsList[i]);
                    }
                }
                component.set("v.paginationListDRCLY", PaginationList);
                component.set("v.totalPagesCountDRCLY", Math.ceil(totalLength / pageSize));
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Get count of transferred deposits
    getTransferredDeposits: function(component,event) {
        console.log('+++getTransferredDeposits+++++');
        var action = component.get("c.getAllTransferredDeposits");
        action.setCallback(this, function(response) {
            var state = response.getState();
            var depositRecords = response.getReturnValue();
            if (state === "SUCCESS"){
                if (depositRecords==0){
                    component.set("v.reviewTransfer", false);
                }
                else{
                    component.set("v.reviewTransfer", true);
                    component.set("v.reviewTransferNumber",depositRecords);
                }
            }
            else{
                component.set("v.reviewTransfer", false);
            }
        });
        $A.enqueueAction(action);
    },

	// Not in use  
    getTenantChangeOverList : function(component, event, helper) {
        var action = component.get("c.getChangeOverDetails");
        action.setCallback(this, function(response) {
            var Result = response.getReturnValue();
            console.log('Changeover Result '+Result);
            if(Result != 'No Change Over Request'){
                //   console.log('Changeover Result '+Result[0].Deposit_Account_Number__r.Id);
                component.set("v.depositChangeOverId",Result);
                component.set("v.reviewTenantChangeOver",true);
                console.log('Line 11 weird -> '+JSON.stringify(component.get("v.depositChangeOverId")));
            }else{
                component.set("v.reviewTenantChangeOver",false);
                
            }
        });
        $A.enqueueAction(action); 
    },		
    */
    
    /* Search Deposit(s) functionality */
    findDepositBySearchText : function(component,event) {
        var registeredNotPaidNumber =0 , awaitingRecieptOfDepositNumber = 0, depositHeldBySafedepositNumber = 0, repaymentbyTenantNumber = 0;
        var registeredNotPaidAmount =0.00, awaitingRecieptOfDepositAmount = 0.00, depositHeldBySafedepositAmount = 0.00, repaymentbyTenantAmount = 0.00;
        var repaymentbyAgentLandlordNumber = 0,selfResolutionNumber = 0,inDisputeResolutionNumber =0 , paymentApproveNumber = 0, depositLastYearNumber = 0;
        var repaymentbyAgentLandlordAmount = 0.00,selfResolutionAmount = 0.00,inDisputeResolutionAmount =0.00, paymentApproveAmount = 0.00, depositLastYearAmount = 0.00;
        var registeredRecords =[] , awaitingRecords =[] ,heldByRecords =[] , tenantRecords =[], agentLandlordRecords =[];
        var selfResolutionRecords =[] , disputeRecords =[] ,repaymentRecords =[] , lastYearRecords =[];
        var searchTextValue =$("#searchValue").val();
        component.set("v.displaySerachDepositRecords", true);
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchid = urlParams.get('branchId');
        var action = component.get("c.getDepositRecordsBySearchText");
        action.setParams({
            'searchText': searchTextValue,branchid : branchid
        }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var allValues = response.getReturnValue();
				console.log('allValues.length '+allValues.length);
                if(allValues.length > 0) {
                    //component.set("v.listOfAllDeposits", allValues);
                    for(var i = 0; i < allValues.length; i++) {
                        
                        if(allValues[i].Status__c==$A.get("$Label.c.Registered_not_paid")) {
                            registeredNotPaidNumber = registeredNotPaidNumber + 1 ;
                            registeredNotPaidAmount = allValues[i].Deposit_Amount__c +  registeredNotPaidAmount;
                            component.set("v.registeredNotPaidNumber", registeredNotPaidNumber);
                            component.set("v.registeredNotPaidAmount", registeredNotPaidAmount.toFixed(2));
                            registeredRecords.push(allValues[i]);
                            
                        } else if(allValues[i].Status__c==$A.get("$Label.c.Awaiting_receipt_of_deposit")) {
                            awaitingRecieptOfDepositNumber = awaitingRecieptOfDepositNumber + 1;
                            awaitingRecieptOfDepositAmount = allValues[i].Protected_Amount__c +  awaitingRecieptOfDepositAmount;
                            component.set("v.paymentSentToSafeDepositNumber", awaitingRecieptOfDepositNumber);
                            component.set("v.paymentSentToSafeDepositAmount", awaitingRecieptOfDepositAmount.toFixed(2));
                            awaitingRecords.push(allValues[i]);
                            
                        } else if(allValues[i].Status__c==$A.get("$Label.c.Deposits_held_by_SafeDeposits_Scotland")){
                            depositHeldBySafedepositNumber = depositHeldBySafedepositNumber + 1;
                            depositHeldBySafedepositAmount = allValues[i].Actual_Protected_Amount__c +  depositHeldBySafedepositAmount;
                            component.set("v.heldBySafeDepositNumber", depositHeldBySafedepositNumber);
                            component.set("v.heldBySafeDepositAmount", depositHeldBySafedepositAmount.toFixed(2));
                            heldByRecords.push(allValues[i]);
                            
                        } else if(allValues[i].Status__c==$A.get("$Label.c.Repayment_requested_by_tenant")){
                            repaymentbyTenantNumber = repaymentbyTenantNumber + 1;
                            repaymentbyTenantAmount = allValues[i].Deposit_Amount__c +  repaymentbyTenantAmount;
                            component.set("v.repaymentRequestedTenantNumber", repaymentbyTenantNumber);
                            component.set("v.repaymentRequestedTenantAmount", repaymentbyTenantAmount.toFixed(2));
                            tenantRecords.push(allValues[i]);
                            
                        } else if(allValues[i].Status__c==$A.get("$Label.c.Repayment_requested_by_agent_landlord")){
                            repaymentbyAgentLandlordNumber = repaymentbyAgentLandlordNumber + 1;
                            repaymentbyAgentLandlordAmount = allValues[i].Deposit_Amount__c +  repaymentbyAgentLandlordAmount;
                            component.set("v.repaymentRequestedAgentLandlordNumber", repaymentbyAgentLandlordNumber);
                            component.set("v.repaymentRequestedAgentLandlordAmount", repaymentbyAgentLandlordAmount.toFixed(2));
                            agentLandlordRecords.push(allValues[i]);
                            
                        } else if(allValues[i].Status__c==$A.get("$Label.c.Self_resolution")){
                            selfResolutionNumber = selfResolutionNumber + 1;
                            selfResolutionAmount = allValues[i].Deposit_Amount__c +  selfResolutionAmount;
                            component.set("v.inDisputeResolutionNumber", selfResolutionNumber);
                            component.set("v.inDisputeResolutionAmount", selfResolutionAmount.toFixed(2));
                            selfResolutionRecords.push(allValues[i]);
                            
                        } else if(allValues[i].Status__c==$A.get("$Label.c.In_dispute_resolution")){
                            inDisputeResolutionNumber = inDisputeResolutionNumber + 1;
                            inDisputeResolutionAmount = allValues[i].Deposit_Amount__c +  inDisputeResolutionAmount;
                            component.set("v.inDisputeResolutionNumber", inDisputeResolutionNumber);
                            component.set("v.inDisputeResolutionAmount", inDisputeResolutionAmount.toFixed(2));
                            disputeRecords.push(allValues[i]);
                            
                        } else if(allValues[i].Status__c==$A.get("$Label.c.Repayment_process")){
                            paymentApproveNumber = paymentApproveNumber + 1;
                            paymentApproveAmount = allValues[i].Deposit_Amount__c +  paymentApproveAmount;
                            component.set("v.paymentApprovedNumber", paymentApproveNumber);
                            component.set("v.paymentApprovedAmount", paymentApproveAmount.toFixed(2));
                            repaymentRecords.push(allValues[i]);
                            
                        } else if(allValues[i].Status__c==$A.get("$Label.c.Deposits_repaid_in_the_last_year")){
                            depositLastYearNumber = depositLastYearNumber + 1;
                            depositLastYearAmount = allValues[i].Deposit_Amount__c +  depositLastYearAmount;
                            component.set("v.depositRepaymentNumber", depositLastYearNumber);
                            component.set("v.depositRepaymentAmount", depositLastYearAmount.toFixed(2));
                            lastYearRecords.push(allValues[i]);
                        }
                    }
                    
                }
               	console.log('registeredRecords '+registeredRecords); 
                if(registeredRecords==null || registeredRecords=='' || registeredRecords==undefined) {
                    component.set("v.registeredNotPaidNumber", 0);
                    component.set("v.registeredNotPaidAmount", 0.00);
                    
                } else {
                    document.getElementById("cardHeader1").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader11").style.color = "#fff";
                    document.getElementById("rowHeader12").style.color = "#fff";
                    document.getElementById("rowHeader13").style.color = "#fff";
                    
                    if(registeredRecords.length > 0) {
                        // Pagination
                        var pageSize = component.get("v.pageSizeRNP");
                        var totalRecordsList = registeredRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountRNP", totalLength);
                        component.set("v.startPageRNP", 0);
                        component.set("v.endPageRNP", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListRNP", PaginationList);
                        component.set("v.totalPagesCountRNP", Math.ceil(totalLength / pageSize));
                    }
                }
                
                if(awaitingRecords==null || awaitingRecords=='' || awaitingRecords==undefined) {
                    component.set("v.paymentSentToSafeDepositNumber", 0);
                    component.set("v.paymentSentToSafeDepositAmount", 0.00);
                    
                } else {
                    document.getElementById("cardHeader2").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader21").style.color = "#fff";
                    document.getElementById("rowHeader22").style.color = "#fff";
                    document.getElementById("rowHeader23").style.color = "#fff";

                    if(awaitingRecords.length > 0){
                        // Pagination
                        var pageSize = component.get("v.pageSizeAP");
                        var totalRecordsList = awaitingRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountAP", totalLength);
                        component.set("v.startPageAP", 0);
                        component.set("v.endPageAP", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListAP", PaginationList);
                        component.set("v.totalPagesCountAP", Math.ceil(totalLength / pageSize));
                    }
                }
                
                if(heldByRecords==null || heldByRecords=='' || heldByRecords==undefined) {
                    component.set("v.heldBySafeDepositNumber", 0);
                    component.set("v.heldBySafeDepositAmount", 0.00);
                    
                } else {
                    document.getElementById("cardHeader3").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader31").style.color = "#fff";
                    document.getElementById("rowHeader32").style.color = "#fff";
                    document.getElementById("rowHeader33").style.color = "#fff";
                    
                    if(heldByRecords.length > 0) {
                        // Pagination
                        var pageSize = component.get("v.pageSizeDHBS");
                        var totalRecordsList = heldByRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountDHBS", totalLength);
                        component.set("v.startPageDHBS", 0);
                        component.set("v.endPageDHBS", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListDHBS", PaginationList);
                        component.set("v.totalPagesCountDHBS", Math.ceil(totalLength / pageSize));
                    }
                    
                }
                
                if(tenantRecords==null || tenantRecords=='' || tenantRecords==undefined) {
                    component.set("v.repaymentRequestedTenantNumber", 0);
                    component.set("v.repaymentRequestedTenantAmount", 0.00);
                    
                } else {
                    document.getElementById("cardHeader4").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader41").style.color = "#fff";
                    document.getElementById("rowHeader42").style.color = "#fff";
                    document.getElementById("rowHeader43").style.color = "#fff";
                    
                    if(tenantRecords.length > 0){
                        // Pagination
                        var pageSize = component.get("v.pageSizeRRbyTenant");
                        var totalRecordsList = tenantRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountRRbyTenant", totalLength);
                        component.set("v.startPageRRbyTenant", 0);
                        component.set("v.endPageRRbyTenant", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListRRbyTenant", PaginationList);
                        component.set("v.totalPagesCountRRbyTenant", Math.ceil(totalLength / pageSize));
                    }
                }
                
                if(agentLandlordRecords==null || agentLandlordRecords=='' || agentLandlordRecords==undefined) {
                    component.set("v.repaymentRequestedAgentLandlordNumber", 0);
                    component.set("v.repaymentRequestedAgentLandlordAmount", 0.00);
                    
                } else {
                    document.getElementById("cardHeader5").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader51").style.color = "#fff";
                    document.getElementById("rowHeader52").style.color = "#fff";
                    document.getElementById("rowHeader53").style.color = "#fff";
                    
                    if(agentLandlordRecords.length > 0) {
                        // Pagination
                        var pageSize = component.get("v.pageSizeRRbyAGLL");
                        var totalRecordsList = agentLandlordRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountRRbyAGLL", totalLength);
                        component.set("v.startPageRRbyAGLL", 0);
                        component.set("v.endPageRRbyAGLL", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListRRbyAGLL", PaginationList);
                        component.set("v.totalPagesCountRRbyAGLL", Math.ceil(totalLength / pageSize));
                    }
                    
                }
                
                if(selfResolutionRecords==null || selfResolutionRecords=='' || selfResolutionRecords==undefined) {
                    component.set("v.selfResolutionNumber", 0);
                    component.set("v.selfResolutionAmount", 0.00);
                    
                } else {
                    document.getElementById("cardHeader6").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader61").style.color = "#fff";
                    document.getElementById("rowHeader62").style.color = "#fff";
                    document.getElementById("rowHeader63").style.color = "#fff";
                    
                    if(selfResolutionRecords.length > 0){
                        // Pagination
                        var pageSize = component.get("v.pageSizeRnotAgrdSR");
                        var totalRecordsList = selfResolutionRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountRnotAgrdSR", totalLength);
                        component.set("v.startPageRnotAgrdSR", 0);
                        component.set("v.endPageRnotAgrdSR", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListRnotAgrdSR", PaginationList);
                        component.set("v.totalPagesCountRnotAgrdSR", Math.ceil(totalLength / pageSize));
                    }
                }
                
                if(disputeRecords==null || disputeRecords=='' || disputeRecords==undefined) {
                    component.set("v.inDisputeResolutionNumber", 0);
                    component.set("v.inDisputeResolutionAmount", 0.00);
                    
                } else {
                    document.getElementById("cardHeader7").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader71").style.color = "#fff";
                    document.getElementById("rowHeader72").style.color = "#fff";
                    document.getElementById("rowHeader73").style.color = "#fff";
                    
                    if(disputeRecords.length > 0) {
                        // Pagination
                        var pageSize = component.get("v.pageSizeRnotAgrdDR");
                        var totalRecordsList = disputeRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountRnotAgrdDR", totalLength);
                        component.set("v.startPageRnotAgrdDR", 0);
                        component.set("v.endPageRnotAgrdDR", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListRnotAgrdDR", PaginationList);
                        component.set("v.totalPagesCountRnotAgrdDR", Math.ceil(totalLength / pageSize));
                    }
                }
                
                if(repaymentRecords==null || repaymentRecords=='' || repaymentRecords==undefined) {
                    component.set("v.paymentApprovedNumber", 0);
                    component.set("v.paymentApprovedAmount", 0.00);
                    
                } else {
                    document.getElementById("cardHeader8").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader81").style.color = "#fff";
                    document.getElementById("rowHeader82").style.color = "#fff";
                    document.getElementById("rowHeader83").style.color = "#fff";
                    
                    if(repaymentRecords.length > 0) {
                        // Pagination
                        var pageSize = component.get("v.pageSizeRP");
                        var totalRecordsList = repaymentRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountRP", totalLength);
                        component.set("v.startPageRP", 0);
                        component.set("v.endPageRP", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListRP", PaginationList);
                        component.set("v.totalPagesCountRP", Math.ceil(totalLength / pageSize));
                    }
                    
                }
                
                if(lastYearRecords==null || lastYearRecords=='' || lastYearRecords==undefined){
                    component.set("v.depositRepaymentNumber", 0);
                    component.set("v.depositRepaymentAmount", 0.00);
                } else {
                    document.getElementById("cardHeader9").style.backgroundColor = "#32669E";
                    document.getElementById("rowHeader91").style.color = "#fff";
                    document.getElementById("rowHeader92").style.color = "#fff";
                    document.getElementById("rowHeader93").style.color = "#fff";
                    
                    if(lastYearRecords.length > 0) {
                        // Pagination
                        var pageSize = component.get("v.pageSizeDRCLY");
                        var totalRecordsList = lastYearRecords;
                        var totalLength = totalRecordsList.length;
                        component.set("v.totalRecordsCountDRCLY", totalLength);
                        component.set("v.startPageDRCLY", 0);
                        component.set("v.endPageDRCLY", pageSize - 1);
                        var PaginationList = [];
                        for (var i = 0; i < pageSize; i++) {
                            if (totalRecordsList.length > i) {
                                PaginationList.push(totalRecordsList[i]);
                            }
                        }
                        component.set("v.paginationListDRCLY", PaginationList);
                        component.set("v.totalPagesCountDRCLY", Math.ceil(totalLength / pageSize));
                    }
                    
                }
                
                component.set("v.registeredNotPaidRecords", registeredRecords);
                component.set("v.paymentSentToSafeDepositRecords", awaitingRecords);
                component.set("v.heldBySafeDepositRecords", heldByRecords);
                component.set("v.repaymentRequestedTenantRecords", tenantRecords);
                component.set("v.repaymentRequestedAgentLandlordRecords", agentLandlordRecords);
                component.set("v.selfResolutionRecords", selfResolutionRecords);
                component.set("v.inDisputeResolutionRecords", disputeRecords);
                component.set("v.paymentApprovedRecords", repaymentRecords);
                component.set("v.depositRepaymentRecords", lastYearRecords);
                
            } else {
                //alert('Error...');
            }
            
        });
        $A.enqueueAction(action);
    },
    
    
})