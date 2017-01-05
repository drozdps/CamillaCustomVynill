public class TrackTriggerHandler implements TriggerTemplate.Handler {
  
    private List<Track__c> newValues = null;
    private Map<Id, Track__c> oldValues = null;
    
    public void setValues(List<sObject> newValues, Map<Id, sObject> oldValues)
    {
        this.newValues = (List<Track__c>)newValues;
        this.oldValues = (Map<Id, Track__c>)oldValues;
    }
    
    public void handle(TriggerTemplate.TriggerAction action)
    {
        if ((action == TriggerTemplate.TriggerAction.beforeInsert)||
            (action == TriggerTemplate.TriggerAction.beforeUpdate))
        {
            List<Track__c> tracksToCheck = new List<Track__c>();
            for (Track__c t : newValues)
                if (t.Song__c != null)
                    tracksToCheck.add(t);
            TrackService.validateTracksNumberAndLength(tracksToCheck);
        }
        if (action == TriggerTemplate.TriggerAction.afterUndelete)
        {
            TrackService.validateTracksNumberAndLength(newValues);
            TrackService.doTracksCountChange(newValues);
            TrackService.doCalculateGenreFrequency(newValues);
        }
        if (action == TriggerTemplate.TriggerAction.afterInsert)
        {
             TrackService.doTracksCountChange(newValues);
             TrackService.doCalculateGenreFrequency(newValues);  
        }
        if (action == TriggerTemplate.TriggerAction.afterUpdate)
        {
          // Process only tracks with new Song__c value 
            List<Track__c> tracks = new List<Track__c>();
            for(Track__c t: newValues)
            {
               if(t.Song__c!= oldValues.get(t.Id).Song__c || t.Mix__c != oldValues.get(t.Id).Mix__c)
               {
                   tracks.add(t);
                   tracks.add(oldValues.get(t.Id));
               }
            }
            TrackService.doTracksCountChange(tracks);
            TrackService.doCalculateGenreFrequency(tracks);
        }
        if (action == TriggerTemplate.TriggerAction.afterDelete)
        {            
            TrackService.doTracksCountChange(oldValues.values());
            TrackService.doCalculateGenreFrequency(oldValues.values());/*oldValues.values()*/
        }       
    }
}