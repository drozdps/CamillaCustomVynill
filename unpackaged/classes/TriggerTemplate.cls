global without sharing class TriggerTemplate
{
    public enum TriggerAction
    {
        afterdelete, afterinsert, afterundelete,
        afterupdate, beforedelete, beforeinsert, beforeupdate
    }
    
    public interface Handler
    {
        void handle(TriggerTemplate.TriggerAction theAction);
        
        void setValues(List<sObject> theNewValues, Map<Id, sObject> theOldValues);
        
    }

    public class TriggerManager
    {
        private Map<String, List<Handler>> eventHandlerMapping = new Map<String, List<Handler>>();
        
        public void addHandler(Handler theHandler, TriggerTemplate.TriggerAction theAction)
        {
            List<Handler> aHandlers = eventHandlerMapping.get(theAction.name());
            if (aHandlers == null)
            {
                aHandlers = new List<Handler>();
                eventHandlerMapping.put(theAction.name(), aHandlers);
            }
            aHandlers.add(theHandler);
        }
    
        public void addHandler(Handler theHandler, List<TriggerTemplate.TriggerAction> theActions)
        {
            for (TriggerAction anAction: theActions)
            {
                addHandler(theHandler, anAction);
            }
        }
        
        public void runHandlers()
        {
            TriggerAction theAction = null;
            if( Trigger.isBefore)
            {
                if (Trigger.isInsert)
                {
                    theAction = TriggerTemplate.TriggerAction.beforeinsert;
                } else if (Trigger.isUpdate)
                {
                    theAction = TriggerTemplate.TriggerAction.beforeupdate;
                } else if (Trigger.isDelete)
                {
                    theAction = TriggerTemplate.TriggerAction.beforedelete;
                }
            } else if (Trigger.isAfter)
            {
                if (Trigger.isInsert)
                {
                    theAction = TriggerTemplate.TriggerAction.afterinsert;
                } else if (Trigger.isUpdate)
                {
                    theAction = TriggerTemplate.TriggerAction.afterupdate;
                } else if (Trigger.isDelete)
                {
                    theAction = TriggerTemplate.TriggerAction.afterdelete;
                } else if (Trigger.isUnDelete)
                {
                    theAction = TriggerTemplate.TriggerAction.afterundelete;
                }
            }
            
            List<Handler> aHandlers = eventHandlerMapping.get(theAction.name());
            if (aHandlers != null && !aHandlers.isEmpty())
            {
                for (Handler aHandler : aHandlers)
                {
                    aHandler.setValues(Trigger.new, Trigger.oldMap);
                    aHandler.handle(theAction);
                }
            }
        }
    }
}