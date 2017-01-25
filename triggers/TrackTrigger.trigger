trigger TrackTrigger on Track__c (after insert, after update, after delete, after undelete)
{
    Set<Id> songIds = new Set<Id>();
    Set<Id> mixIds = new Set<Id>();

    if (trigger.isInsert || trigger.isUndelete)
    {
        for (Track__c t: Trigger.New)
        {
            songIds.add(t.Song__c);
            mixIds.add(t.Mix__c);
        }
    }
    else if (trigger.isUpdate)
    {
        for (Track__c t: Trigger.New)
        {
            songIds.add(t.Song__c);
            mixIds.add(t.Mix__c);
        }
        for (Track__c t: Trigger.Old)
        {
            songIds.add(t.Song__c);
            mixIds.add(t.Mix__c);
        }
    }
    else if (trigger.isDelete)
    {
        for (Track__c t: Trigger.Old)
        {
            songIds.add(t.Song__c);
            mixIds.add(t.Mix__c);
        }
    }
    TrackTriggerHandler.calculateTracks(songIds);
    TrackTriggerHandler.defineGenre(mixIds);
}