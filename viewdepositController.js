({
    doneWaiting: function(component, event, helper) {
     
    },
    
    doInit : function(component, event, helper) {
      
            
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
    
      var branchId=null;
    var branch = urlParams.get('branchId');
       
        var branchIdList=''
        if(branch != null ){
         
             branchIdList = atob(urlParams.get('branchId'));
                 const myArray = branchIdList.split("&");
            
 		 let myName;
        var branchId;
        if(myArray.length >2){
            myName = myArray[0]+'&'+myArray[1];
             branchId = myArray[2];
            
        }else{
            myName = myArray[0];
             branchId = myArray[1];
        }
          var cookie ={
        	getCookie: function (strName) {
				var name = strName + "=";
				var ca = document.cookie.split(';');
				for (var i = 0; i < ca.length; i++) {
					var c = ca[i];
					while (c.charAt(0) == ' ') {
						c = c.substring(1);
					}
					if (c.indexOf(name) == 0) {
						return c.substring(name.length, c.length);
					}
				}
				return false;
            },
          }
          
              var uName = cookie.getCookie("UName");
     
            if(uName != myName){
               
                helper.logoutHelper(component);
            }
        }
        
        const redirectFromPayment = urlParams.get('redirect');
        
        if(branchId == null) {
            component.set("v.branchUser",true);
            
        } else {
            component.set("v.branchUser",false);
        }
        
        if(redirectFromPayment == null) {
            //  console.log('redirectFromPayment '+redirectFromPayment);
            component.set("v.redirectFromPayment",false);
            
        } else { 
            component.set("v.redirectFromPayment",true);
        }
        
       // console.log('redirectFromPayment '+component.get("v.redirectFromPayment"));
        
        /*helper.getDeposits(component, event, helper); // For getting all the deposits and finding the amount sum
        helper.getDepositsRegisteredNotpaid(component, event, helper);
        helper.getPaymentsSentSafeDeposits(component, event, helper);
        helper.getPaymentsHeldSafeDeposits(component, event, helper);
        helper.getRepaymentsRequestedTenants(component, event, helper);
        helper.getRepaymentsRequestedAgentLandlord(component, event, helper);
        helper.getSelfResolutionResolution(component, event, helper);
        helper.getInDisputeResolution(component, event, helper);
        helper.getPaymentApproved(component, event, helper);
        helper.getDepositRepaymentLastMonth(component, event, helper);
        helper.getTransferredDeposits(component, event); 
        helper.getTenantChangeOverList(component, event,helper);*/
        
        //helper.getAllDeposits(component, event,helper); // Latest made 
        
        helper.serverCallHelper(component,'getAllDeposits',{ branchid : branchId })
        .then(function(result) {
            var allDepositStatusesList = result;
            component.set("v.allDepositsList", allDepositStatusesList);
         //   console.log('Line 55 weird123 -> '+JSON.stringify(allDepositStatusesList));
           console.log('Line 56 weird123 -> '+allDepositStatusesList.length);
            
            console.log('allDepositStatusesList[0].countTransferredDeposits : ' , allDepositStatusesList[0].countTransferredDeposit );
        //    console.log('Call 1 weird123 ttyl : ' , JSON.stringify(result));
            
            if(allDepositStatusesList.length>0) {
                if (allDepositStatusesList[0].countTransferredDeposit==0) {
                    component.set("v.reviewTransfer", false);
                    component.set("v.reviewTransferNumber",allDepositStatusesList[0].countTransferredDeposit);
                    
                } else {
                    component.set("v.reviewTransfer", true);
                    component.set("v.reviewTransferNumber",allDepositStatusesList[0].countTransferredDeposit);
                }
          //      console.log('Call 2 weird123 length depo : ' , allDepositStatusesList[0].depositsOfAllStatus.length);
                helper.getDepositsByStatuses(component, allDepositStatusesList[0].depositsOfAllStatus);
            }
            component.set("v.PageSpinner",false); 
        })
                
    },
    
    getCurrentUser: function(component, event, helper) {
        console.log('>>>>>>>>')
        var currentUser = component.get("v.currentUser");
        console.log('>>>>>>>>'+currentUser)
        if(currentUser.Contact.Job_role__c=='Deposit, property & dispute administrator' || 
           currentUser.Contact.Job_role__c=='Deposit & property administrator'  || 
           currentUser.Contact.Job_role__c=='Head office administrator' || 
           currentUser.Contact.Job_role__c=='Account administrator' || 
           currentUser.Contact.Additional_Permission__c=='Add deposit')
        {
            component.set("v.addDeposit",true);
        }  
    },
    
    searchproperty: function(component, event, helper) {
         var rac = component.get("v.searchText");
     //   console.log(rac);
        if (event.keyCode === 13) {
     //       console.log('clicked');
            helper.findDepositBySearchText(component, event);
        }else{
            
        }
    },
    
    backtobranch : function(component, event, helper) {
        /*  let currentURL = window.location.origin;
       // let pathName = "/Sds/s/branches";
        let pathName = "/Sds/s";
        window.location.href = currentURL+pathName;*/
        event.preventDefault();
        
        var urlRedirect = $A.get("$Label.c.Lightning_Component_URL");
        window.location.replace(urlRedirect);
        return false;
        
    },
    
    addDeposit : function(component, event, helper) {
        
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const branchId = urlParams.get('branchId');
        
        if(branchId != null){
            component.find("navService").navigate({
                type: "comm__namedPage",
                attributes: {
                    pageName: "adddeposit"
                },
                state: {
                    branchId: branchId
                }
            });
        }
        else{
            component.find("navService").navigate({
                type: "comm__namedPage",
                attributes: {
                    pageName: "adddeposit"
                },
                state: {
                    
                }
            });
        }
        
    },
    
    reviewChangeOver : function(component, event, helper) {
        var depositId = event.getSource().get("v.name");        
        if(typeof depositId != 'undefined'){
            component.find("navService").navigate({
                type: "comm__namedPage",
                attributes: {
                    pageName: "tenantchangeoverresponsebyagll"
                },
                state: {
                    id : depositId,
                    tchange : true
                }
            });
        }
    },
    
    viewRevewTransferredDeposits : function(component, event, helper) {
        var PageName = "";
        if(component.get("v.reviewTransferNumber") > 1){
            PageName = "bulkactions";
        }else{
            PageName = "reviewtransfer";
        }
        component.find("navService").navigate({
            type: "comm__namedPage",
            attributes: {
                pageName: PageName
            },
            state: {}
        });
        //var urlRedirect = $A.get("$Label.c.Lightning_Component_URL")+"reviewtransfer";
        //window.location.replace(urlRedirect);
        // return false;
    },
    
    handleRowAction : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        var branchVal = urlParams.get('branchId');
          const  branchId = urlParams.get('branchId');
        var name = component.get("v.currentUser.TestName__c");
      
        setTimeout(function(){ 
             console.log('tt')
         const depositId = btoa(name+'&'+event.target.id);
           
          var state;
            console.log('name '+name);
      //  alert(branchId+' = dep -'+depositId);
        if(branchVal != null){
            state = {
                id : depositId,
                branchId : branchId
            };
        }else{
            state = {
                id : depositId
            };
        }
        
           // const encodedId = btoa("depositsummarypage");
            //alert(encodedId);
            component.find("navService").navigate({
                type: "comm__namedPage",
                attributes: {
                    pageName: "depositsummarypage"
                },
                state: state
            });
        }, 500);        
        
    },
    
    handleClick : function(component, event, helper) {
        helper.findDepositBySearchText(component, event);
        component.set("v.displaySerachDepositRecords", true);
    },
    
    navPageRNP : function(component, event, helper) {
        var sObjectList = component.get("v.registeredNotPaidRecords");
        var end = component.get("v.endPageRNP");
        var start = component.get("v.startPageRNP");
        var pageSize = component.get("v.pageSizeRNP");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageRNP", component.get("v.currentPageRNP") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageRNP", start);
            component.set("v.endPageRNP", end);
            component.set("v.paginationListRNP", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageRNP", component.get("v.currentPageRNP") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageRNP", start);
            component.set("v.endPageRNP", end);
            component.set("v.paginationListRNP", Paginationlist);
        }
    },
    
    navPageAP : function(component, event, helper) {
        var sObjectList = component.get("v.paymentSentToSafeDepositRecords");
        var end = component.get("v.endPageAP");
        var start = component.get("v.startPageAP");
        var pageSize = component.get("v.pageSizeAP");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageAP", component.get("v.currentPageAP") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageAP", start);
            component.set("v.endPageAP", end);
            component.set("v.paginationListAP", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageAP", component.get("v.currentPageAP") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageAP", start);
            component.set("v.endPageAP", end);
            component.set("v.paginationListAP", Paginationlist);
        }
    },
    
    navPageDHBS : function(component, event, helper) {
        var sObjectList = component.get("v.heldBySafeDepositRecords");
        var end = component.get("v.endPageDHBS");
        var start = component.get("v.startPageDHBS");
        var pageSize = component.get("v.pageSizeDHBS");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageDHBS", component.get("v.currentPageDHBS") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageDHBS", start);
            component.set("v.endPageDHBS", end);
            component.set("v.paginationListDHBS", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageDHBS", component.get("v.currentPageDHBS") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageDHBS", start);
            component.set("v.endPageDHBS", end);
            component.set("v.paginationListDHBS", Paginationlist);
        }
    },
    
    navPageRRbyTenant : function(component, event, helper) {
        var sObjectList = component.get("v.repaymentRequestedTenantRecords");
        var end = component.get("v.endPageRRbyTenant");
        var start = component.get("v.startPageRRbyTenant");
        var pageSize = component.get("v.pageSizeRRbyTenant");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageRRbyTenant", component.get("v.currentPageRRbyTenant") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageRRbyTenant", start);
            component.set("v.endPageRRbyTenant", end);
            component.set("v.paginationListRRbyTenant", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageRRbyTenant", component.get("v.currentPageRRbyTenant") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageRRbyTenant", start);
            component.set("v.endPageRRbyTenant", end);
            component.set("v.paginationListRRbyTenant", Paginationlist);
        }
    },
    
    navPageRRbyAGLL : function(component, event, helper) {
        var sObjectList = component.get("v.repaymentRequestedAgentLandlordRecords");
        var end = component.get("v.endPageRRbyAGLL");
        var start = component.get("v.startPageRRbyAGLL");
        var pageSize = component.get("v.pageSizeRRbyAGLL");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageRRbyAGLL", component.get("v.currentPageRRbyAGLL") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageRRbyAGLL", start);
            component.set("v.endPageRRbyAGLL", end);
            component.set("v.paginationListRRbyAGLL", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageRRbyAGLL", component.get("v.currentPageRRbyAGLL") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageRRbyAGLL", start);
            component.set("v.endPageRRbyAGLL", end);
            component.set("v.paginationListRRbyAGLL", Paginationlist);
        }
    },
    
    navPageRnotAgrdSR : function(component, event, helper) {
        var sObjectList = component.get("v.selfResolutionRecords");
        var end = component.get("v.endPageRnotAgrdSR");
        var start = component.get("v.startPageRnotAgrdSR");
        var pageSize = component.get("v.pageSizeRnotAgrdSR");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageRnotAgrdSR", component.get("v.currentPageRnotAgrdSR") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageRnotAgrdSR", start);
            component.set("v.endPageRnotAgrdSR", end);
            component.set("v.paginationListRnotAgrdSR", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageRnotAgrdSR", component.get("v.currentPageRnotAgrdSR") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageRnotAgrdSR", start);
            component.set("v.endPageRnotAgrdSR", end);
            component.set("v.paginationListRnotAgrdSR", Paginationlist);
        }
    },
    
    navPageRnotAgrdDR : function(component, event, helper) {
        var sObjectList = component.get("v.inDisputeResolutionRecords");
        var end = component.get("v.endPageRnotAgrdDR");
        var start = component.get("v.startPageRnotAgrdDR");
        var pageSize = component.get("v.pageSizeRnotAgrdDR");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageRnotAgrdDR", component.get("v.currentPageRnotAgrdDR") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageRnotAgrdDR", start);
            component.set("v.endPageRnotAgrdDR", end);
            component.set("v.paginationListRnotAgrdDR", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageRnotAgrdDR", component.get("v.currentPageRnotAgrdDR") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageRnotAgrdDR", start);
            component.set("v.endPageRnotAgrdDR", end);
            component.set("v.paginationListRnotAgrdDR", Paginationlist);
        }
    },
    
    navPageRP : function(component, event, helper) {
        var sObjectList = component.get("v.paymentApprovedRecords");
        var end = component.get("v.endPageRP");
        var start = component.get("v.startPageRP");
        var pageSize = component.get("v.pageSizeRP");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageRP", component.get("v.currentPageRP") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageRP", start);
            component.set("v.endPageRP", end);
            component.set("v.paginationListRP", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageRP", component.get("v.currentPageRP") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageRP", start);
            component.set("v.endPageRP", end);
            component.set("v.paginationListRP", Paginationlist);
        }
    },
    
    navPageDRCLY : function(component, event, helper) {
        var sObjectList = component.get("v.depositRepaymentRecords");
        var end = component.get("v.endPageDRCLY");
        var start = component.get("v.startPageDRCLY");
        var pageSize = component.get("v.pageSizeDRCLY");
        //var whichBtn = event.getSource().get("v.name");
        //
        // check if whichBtn value is 'next' then call 'next' helper method
        if (event.target.id == "nextId") {
            component.set("v.currentPageDRCLY", component.get("v.currentPageDRCLY") + 1);
            //helper.next(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = end + 1; i < end + pageSize + 1; i++) {
                if (sObjectList.length > i) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                }
                counter++;
            }
            start = start + counter;
            end = end + counter;
            component.set("v.startPageDRCLY", start);
            component.set("v.endPageDRCLY", end);
            component.set("v.paginationListDRCLY", Paginationlist);
        }
        // check if whichBtn value is 'previous' then call 'previous' helper method
        else if (event.target.id == "previousId") {
            component.set("v.currentPageDRCLY", component.get("v.currentPageDRCLY") - 1);
            //helper.previous(component, event, sObjectList, end, start, pageSize);
            var Paginationlist = [];
            var counter = 0;
            for (var i = start - pageSize; i < start; i++) {
                if (i > -1) {
                    {
                        Paginationlist.push(sObjectList[i]);
                    }
                    counter++;
                } else {
                    start++;
                }
            }
            start = start - counter;
            end = end - counter;
            component.set("v.startPageDRCLY", start);
            component.set("v.endPageDRCLY", end);
            component.set("v.paginationListDRCLY", Paginationlist);
        }
    },
    
})