public class TrackService {

    public static void doTracksCountChange(List<Track__c> tracks)
    {
        Set<Id> songIds = new Set<Id>();
        for (Track__c t: tracks)
            if (t.Song__c!= null)
                songIds.add(t.Song__c);  // if track has no song
        List<Song__c> songsToChange = new List<Song__c>();        
        List<AggregateResult> aggrSet = [SELECT Song__c SongId, Count(id) NumberOfSongs FROM Track__c WHERE Song__c IN: songIds GROUP BY Song__c];
        Set<Id> changedSongs = new Set<Id>();

        for (AggregateResult ar : aggrSet)
        {
            songsToChange.add(new Song__c(Id=(Id) ar.get('SongId'),Track_Count__c=(Integer) ar.get('NumberOfSongs')));
            changedSongs.add((Id)ar.get('SongId'));
        }
        // Songs with empty AggregationResult have no tracks
        for (Song__c s : [SELECT Id,Track_Count__c FROM Song__c WHERE Id IN :songIds AND Id NOT IN :changedSongs ])
            songsToChange.add(new Song__c(Id  = s.Id,Track_Count__c=0));
        update songsToChange;
    }

    public static void doCalculateGenreFrequency(List<Track__c> tracks)
    {
        Set<Id> mixIds = new Set<Id>();
        for (Track__c t: tracks)
            mixIds.add(t.Mix__c);
        List<AggregateResult> aggrResult = [SELECT  Mix__c mixId, Song__r.Genre__c genre,COUNT(Song__c) FROM Track__c
                                           WHERE Mix__c IN :mixIds GROUP BY Song__r.Genre__c  ,Mix__c
                                           ORDER BY Mix__c ASC, COUNT(Song__c) DESC, Song__r.Genre__c ASC ];
        List<Mix__c> mixesToChange = new List<Mix__c>();
        Map<Id,List<String>> mixToGenres = new Map<Id,List<String>>();
        for (Id mixId : mixIds)
            mixToGenres.put(mixId,new List<String>()); // Some mixes can have empty AggregationResult
        for (AggregateResult aggr: aggrResult)
            if (((String)aggr.get('genre')) != null && !((String)aggr.get('genre')).equals(''))
            mixToGenres.get((Id)aggr.get('mixId')).add((String)aggr.get('genre'));
        for (Id mixId : mixToGenres.keySet())
            mixesToChange.add(new Mix__c(Id = mixId,
                    PrimaryGenre__c = mixToGenres.get(mixId).size() == 0 ? '' : mixToGenres.get(mixId).get(0),
                    SecondaryGenre__c = mixToGenres.get(mixId).size() > 1 ? mixToGenres.get(mixId).get(1) : ''));
        update mixesToChange;
    }

    public static void validateTracksNumberAndLength(List<Track__c> tracks)
    {
       
        Map<Id, List<Double>> aggrList = new Map<Id, List<Double>>();
        Set<Id> songIds = new Set<Id>();
        Set<Id> trackIds = new Set<Id>();
        for (Track__c t : tracks)
        {
            trackIds.add(t.Id);
            songIds.add(t.Song__c);
            aggrList.put(t.Mix__c, new List<Double>{0,0});
            
        }
        List<AggregateResult> aggrResult=[SELECT Mix__c mixId, COUNT(Id) tracksNumber, SUM(Song__r.Length_m__c) length
                                          FROM Track__c WHERE Mix__c IN :aggrList.keySet() AND Id NOT IN :trackIds GROUP BY Mix__c ];
        Map<Id, Song__c> songs =  new Map<Id,Song__c>([SELECT Id, Length_m__c, Track_Count__c, Track_Licenses__c, Name FROM Song__c WHERE Id IN :songIds]);
        Map<Id, Integer> songsTrackCount = new Map<Id,Integer>();
        for (Song__c s : songs.values())
            songsTrackCount.put(s.Id, (Integer)s.Track_Count__c);
        for (AggregateResult aggr : aggrResult)
            aggrList.put((Id)aggr.get('mixId'), new List<Double>{(Integer)aggr.get('tracksNumber'), (Double)aggr.get('length')});
        for (Track__c t: tracks)
        {
            Integer tracksNumber =(Integer) aggrList.get(t.Mix__c)[0]+1; 
            Double length = aggrList.get(t.Mix__c)[1]+songs.get(t.Song__c).Length_m__c;
            aggrList.put(t.Mix__c,new List<Double>{tracksNumber, length});
            songsTrackCount.put(t.Song__c,songsTrackCount.get(t.Song__c)+1);
            if (tracksNumber > 20)
                t.addError('More than 20 tracks');                    
            if (length > 90)
                t.addError('Mix total length exceeds 90 min.'); 
            if (songsTrackCount.get(t.Song__c) > songs.get(t.Song__c).Track_Licenses__c)
                t.addError('Track licenses exceeded for song "'+songs.get(t.Song__c).Name+'"');          
        }                
                       
    }
}