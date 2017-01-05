trigger TrackTrigger on Track__c (after insert, after update, after delete, after undelete,before update,before insert) {
	TriggerTemplate.TriggerManager triggerManager = new TriggerTemplate.TriggerManager();
	triggerManager.addHandler(new TrackTriggerHandler(), new List<TriggerTemplate.TriggerAction>{ 
        TriggerTemplate.TriggerAction.afterInsert, TriggerTemplate.TriggerAction.afterUpdate,
             TriggerTemplate.TriggerAction.afterDelete, TriggerTemplate.TriggerAction.afterUndelete,
            TriggerTemplate.TriggerAction.beforeUpdate,TriggerTemplate.TriggerAction.beforeInsert});
	triggerManager.runHandlers();
}