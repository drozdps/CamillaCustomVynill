// INACTIVE
public class MixTriggerHandler  implements TriggerTemplate.Handler{
    private List<Mix__c> newValues = null;
    private Map<Id, Mix__c> oldValues = null;

    public void setValues(List<sObject> newValues, Map<Id, sObject> oldValues)
    {
        this.newValues = (List<Mix__c>)newValues;
        this.oldValues = (Map<Id, Mix__c>)oldValues;
    }

    public void handle(TriggerTemplate.TriggerAction action)
    {
        if (action == TriggerTemplate.TriggerAction.beforedelete)
        {
            List<Song__c> songsToUpdate = new List<Song__c>();
            List<Track__c> tracksToDelete = new List<Track__c>();
            for (Mix__c m : oldValues.values())
                tracksToDelete.addAll([SELECT Id,Song__c,Mix__c FROM Track__c WHERE Mix__c = :m.Id]);
            TrackService.doTracksCountChange(tracksToDelete);
            /*for (Track__c t : tracksToDelete)
            {
                Song__c s = [SELECT Id,Name,Track_Count__c FROM Song__c WHERE Id = :t.Song__c];
                s.Track_Count__c--;
                songsToUpdate.add(s);
            }
            update songsToUpdate;*/
        }
 
        if (action == TriggerTemplate.TriggerAction.afterundelete)
        {
            List<Track__c> tracksToUndelete = new List<Track__c>();
            List<Track__c> tracksToInsert = new List<Track__c>();
            for(Mix__c m : newValues)
                tracksToUndelete.addAll(new List<Track__c>([SELECT Song__c,Mix__c FROM Track__c WHERE Mix__c = :m.Id]));
            for(Track__c t : tracksToUndelete)
                tracksToInsert.add(new Track__c(Mix__c = t.Mix__c, Song__c = t.Song__c));

            delete tracksToUndelete;
            Database.emptyRecycleBin(tracksToUndelete);
            insert tracksToInsert;
        }


    }
}