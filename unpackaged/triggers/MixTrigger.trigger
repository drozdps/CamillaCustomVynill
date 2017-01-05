trigger MixTrigger on Mix__c (before delete, after undelete) {
    TriggerTemplate.TriggerManager triggerManager = new TriggerTemplate.TriggerManager();
    triggerManager.addHandler(new MixTriggerHandler(), new List<TriggerTemplate.TriggerAction>{
            TriggerTemplate.TriggerAction.beforedelete, TriggerTemplate.TriggerAction.afterundelete});
    triggerManager.runHandlers();
}