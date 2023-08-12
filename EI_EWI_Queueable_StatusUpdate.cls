public class EI_EWI_Queueable_StatusUpdate implements Queueable {
    list<Id> recIds = new list<Id>();
    public EI_EWI_Queueable_StatusUpdate(List<id> RecId) {
        this.recIds= RecId;
    }
    public void execute(QueueableContext context) {
        
        EI_EWI_CaseStatusUpdateApi.initiateCallOut(recIds);        
    }

}