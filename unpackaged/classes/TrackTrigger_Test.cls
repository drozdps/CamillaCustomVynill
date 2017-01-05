@isTest
public class TrackTrigger_Test{

    static final Integer TEST_MIXES_COUNT = 5;
    static final Integer MAX_TRACKS_COUNT = 15;
    static final Integer TEST_SONG_NUMBER = 18;
    static final Integer MAX_TRACK_COUNT = 20;
    static final Integer MAX_MIX_LENGTH = 90;

    @testSetup static void setup(){
        TestDataFactory.initializeTest();
    }

    @isTest static void delete_ShouldChangeTrackCountInSongAndGenresFrequencyInMix()
    {
        Mix__c mix = TestDataFactory.getRandomMix();
        List<Song__c> availableSongs = [SELECT Id, Genre__c FROM Song__c];
        List<Track__c> tracks = TestDataFactory.createRelatedTracks(mix,false);

        Test.startTest();
        delete tracks;
        Test.stopTest();

        mix = [SELECT Id, PrimaryGenre__c, SecondaryGenre__c FROM Mix__c WHERE Id=:mix.Id];
        System.assertEquals(null, mix.PrimaryGenre__c);
        System.assertEquals(null, mix.SecondaryGenre__c);
        for (Song__c s : [SELECT Track_Count__c FROM Song__c])
            System.assertEquals(0,s.Track_Count__c);
    }

    @istest static void undelete_ShouldRestoreTrackCountInSongAndGenresFrequencyInMix()
    {
        Mix__c mix = TestDataFactory.getRandomMix();
        List<Song__c> availableSongs = [SELECT Id, Genre__c FROM Song__c];
        List<Track__c> tracks = TestDataFactory.createRelatedTracks(mix,false);
        delete tracks;

		Test.startTest();
        undelete tracks;
        Test.stopTest();

        mix = [SELECT Id, PrimaryGenre__c, SecondaryGenre__c FROM Mix__c WHERE Id=:mix.Id];
        System.assertEquals(availableSongs.get(0).Genre__c, mix.PrimaryGenre__c);
        System.assertEquals(availableSongs.get(1).Genre__c, mix.SecondaryGenre__c);
        for(Song__c s : [SELECT Track_Count__c FROM Song__c])
            System.assertEquals(1,s.Track_Count__c);
    }
    @isTest static void undelete_ShouldCauseTriggerValidationErrors()
    {
        Mix__c mix = TestDataFactory.getRandomMix();
        List<Song__c> availableSongs = [SELECT Id, Genre__c,Track_Licenses__c FROM Song__c];
        List<Track__c> tracks = TestDataFactory.createRelatedTracks(mix,false);
        delete tracks;

		Mix__c anotherMix = TestDataFactory.getRandomMix(mix);
        List<Track__c> newTracks = new List<Track__c>();
        for (Integer i = 0; i < availableSongs.get(0).Track_Licenses__c; i++)
            newTracks.add(new Track__c(Mix__c = anotherMix.Id, Song__c = availableSongs.get(0).Id));
        insert newTracks;

		Test.startTest();
        List<Database.UndeleteResult> sr = Database.undelete(tracks,false);
        Test.stopTest();

        for(Database.UndeleteResult r : sr)
        System.assertEquals(false,sr.get(0).isSuccess());
    }
    @isTest static void update_ShouldChangeTrackCountInSongAndGenresFrequencyInMix()
    {
        Mix__c mix = TestDataFactory.getRandomMix();
        List<Song__c> availableSongs = [SELECT Id, Genre__c FROM Song__c];
        List<Track__c> tracks = TestDataFactory.createRelatedTracks(mix,false);
        tracks.get(0).Song__c = availableSongs.get(12).Id;

        Test.startTest();
        update tracks.get(0);
        Test.stopTest();

        mix = [SELECT  Id, Name, PrimaryGenre__c, SecondaryGenre__c FROM Mix__c WHERE Id =: mix.Id];
        System.assertEquals('Opera', mix.PrimaryGenre__c);
        System.assertEquals('Blues', mix.SecondaryGenre__c);
        System.assertEquals(2, [SELECT Id,Track_Count__c FROM Song__c WHERE Id =: availableSongs.get(12).Id].Track_Count__c);
    }

    @isTest static void update_ShouldCauseTriggerValidationErrors()
    {
        Mix__c mix = TestDataFactory.getRandomMix();
        List<Song__c> availableSongs = [SELECT Id, Genre__c,Track_Licenses__c FROM Song__c];
        List<Track__c> tracks = TestDataFactory.createRelatedTracks(mix,true);
        tracks.add(new Track__c(Mix__c = mix.Id, Song__c = availableSongs.get(1).Id));
        insert tracks.get(tracks.size()-1);

        tracks.get(tracks.size()-1).Song__c = availableSongs.get(0).Id;

        Test.startTest();
        Database.SaveResult sr = Database.update(tracks.get(tracks.size() - 1), false);
        Test.stopTest();

        System.assertEquals(false,sr.success);
    }

    @isTest
    public static void insert_ShouldChangeTrackCountInSongAndGenresFrequencyInMix(){
        List<Track__c> tracks = new List<Track__c>();
        List<Song__c> availableSongs = [SELECT Id,Name,Genre__c FROM Song__c];
        Map<Id,Integer> songsTrackNumber = new Map<Id, Integer>();
        // Ensure that there will be enough licenses for each song to include it in track
        for (Song__c s : availableSongs)
        {
            s.Track_Licenses__c = 1000;
            songsTrackNumber.put(s.Id, 0);
        }
        update availableSongs;
        availableSongs = [SELECT Id, Name, Genre__c FROM Song__c];
        Map<Id, FilledMix> filledMixes = new Map<Id, FilledMix>();
        for (Mix__c m : [SELECT Name,Id FROM Mix__c])
        {
            Map<String, List<Song__c>> genresToSongs = new Map<String, List<Song__c>>();
             // For each mix insert random number of random songs
            for (Integer  i = 0; i < (Integer)Math.mod(Math.round(Math.random()*1000), MAX_TRACK_COUNT); i++)
            {
                // Choose random song from available songs
                Song__c songToAdd = availableSongs.get((Integer)Math.mod(Math.round(Math.random()*1000), 18));
                if (!genresToSongs.containsKey(songToAdd.Genre__c))
                    genresToSongs.put( (songToAdd.Genre__c != null) ? songToAdd.Genre__c : '', new List<Song__c>{songToAdd});
                else
                {
                    List<Song__c> sl = genresToSongs.get(songToAdd.Genre__c);
                    sl.add(songToAdd);
                    genresToSongs.put( (songToAdd.Genre__c != null) ? songToAdd.Genre__c : '', sl);
                }
                songsTrackNumber.put(songToAdd.Id, songsTrackNumber.get(songToAdd.Id)+1);
                tracks.add(new Track__c(Mix__c = m.Id, Song__c =songToAdd.Id));
            }
            filledMixes.put(m.Id, new FilledMix(m,genresToSongs));

        }
        Test.startTest();
        insert tracks;
        Test.stopTest();
        for (Mix__c m : [SELECT Id, PrimaryGenre__c, SecondaryGenre__c FROM Mix__c])
        {
            System.assertEquals(filledMixes.get(m.Id).primaryGenre, (m.PrimaryGenre__c == null) ? '' : m.PrimaryGenre__c);
            System.assertEquals(filledMixes.get(m.Id).secondaryGenre,(m.SecondaryGenre__c == null) ? '' : m.SecondaryGenre__c);
        }
        for (Song__c s : [SELECT Id, Track_Count__c FROM Song__c])
        {
            System.assertEquals(songsTrackNumber.get(s.Id),s.Track_Count__c);
        }
    }
    @isTest
    public static void insert_ShouldCauseTriggerValidationErrors()
    {
        List<Track__c> tracks1 = new List<Track__c>();
        List<Track__c> tracks2 = new List<Track__c>();
        Integer randomIndex1 = (Integer)Math.mod(Math.round(Math.random()*1000), TEST_SONG_NUMBER);
        Integer randomIndex2 = (randomIndex1 != 0) ? randomIndex1-1 : randomIndex1+1;
        Song__c randomSong1 = [SELECT Id, Name, Genre__c, Track_Licenses__c FROM Song__c].get(randomIndex1);
        Song__c randomSong2 = [SELECT Id, Track_Licenses__c FROM Song__c].get(randomIndex2);
        randomSong2.Track_Licenses__c = MAX_TRACK_COUNT + 1;
        update randomSong2;

        randomIndex1 = (Integer)Math.mod( Math.round( Math.random() * 1000 ), TEST_MIXES_COUNT);
        randomIndex2 = (randomIndex1 != 0) ? randomIndex1 - 1 : randomIndex1 + 1;
        Mix__c randomMix1 = [SELECT Id, Name FROM Mix__c].get(randomIndex1);
        Mix__c randomMix2 = [SELECT Id, Name FROM Mix__c].get(randomIndex2);

        for (Integer i = 0; i < randomSong1.Track_Licenses__c + 1; i++)
            tracks1.add(new Track__c(Mix__c = randomMix1.Id, Song__c = randomSong1.Id));
        for (Integer i = 0; i < MAX_TRACK_COUNT + 1; i++)
            tracks2.add(new Track__c(Mix__c = randomMix2.Id, Song__c = randomSong2.Id));

        Test.startTest();
        List<Database.SaveResult> sr1 = Database.insert(tracks1, false); // track licenses error
        List<Database.SaveResult> sr2 = Database.insert(tracks2, false); // track number in mix error
        Test.stopTest();

        // Should fail on the last track
        System.assertEquals(false, sr1.get(sr1.size()-1).success);
        System.assertEquals(false, sr2.get(sr2.size()-1).success);
    }

    private class FilledMix
    {
        public Map<String, List<Song__c>> genresToSongs;
        public String primaryGenre;
        public String secondaryGenre;
        public FilledMix(Mix__c mix, Map<String, List<Song__c>> genresToSongs)
        {
            this.genresToSongs = genresToSongs;
            primaryGenre = '';
            secondaryGenre = '';
            calculatePrimaryGenre();
            calculateSecondaryGenre();
        }
        private void calculatePrimaryGenre()
        {
            Integer primaryCount = 0;
            for (String genre : getSortedKeyset(genresToSongs))
            {
                if (genresToSongs.get(genre).size() > primaryCount  && !genre.equals(''))
                {
                    primaryCount = genresToSongs.get(genre).size();
                    primaryGenre = genre;
                }
            }
        }
        private void calculateSecondaryGenre()
        {
            Integer secondaryCount = 0;
            for (String genre : getSortedKeyset(genresToSongs))
            {
                if (genresToSongs.get(genre).size() > secondaryCount && !primaryGenre.equals(genre) && !genre.equals(''))
                {
                    secondaryCount = genresToSongs.get(genre).size();
                    secondaryGenre = genre;
                }
            }
        }
        private List<String> getSortedKeyset(Map<String, List<Song__c>> dataMap) {
            List<String> keySetList = new List<String>();
            keySetList.addAll(dataMap.keySet());
            keySetList.sort();
            return keySetList;
        }
    }

}