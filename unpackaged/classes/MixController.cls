public class MixController
{
    @TestVisible private static final Integer RECORDS_PER_PAGE = 10;
    private static final Double MAX_TRACK_LENGTH = 90.00;
    private static final Integer MAX_TRACK_COUNT = 20;
    @TestVisible private List<SongWrapper> wrappers; // Contains songs from current page
    @TestVisible private Map <Id, Song__c> selectedSongs;
    @TestVisible private ApexPages.StandardSetController setCon;
    public Mix__c mix {get; private set; }
    public string genreToShow {get; set; }
    public String query = 'SELECT Name,Genre__c,Length_m__c FROM Song__c';
    public Integer trackCount {get; set;}
    public Double trackLength {get; set;}
    public integer pageNumber
    {
        get
            {
                return Setcon.getPageNumber();
            }
    }
    public Integer totalPages
    {
        get
            {
                return (Integer)(setCon.getResultSize() / ((Decimal)RECORDS_PER_PAGE)).round(System.RoundingMode.CEILING);
            }
    }

    public MixController()
    {
        setCon = new ApexPages.StandardSetController(Database.query(String.escapeSingleQuotes(query)));
        setCon.setpagesize(RECORDS_PER_PAGE);
        selectedSongs = new Map <id,Song__c>();
        trackLength = 0;
        trackCount = 0;
        Id id = ApexPages.currentPage().getParameters().get('id');
        mix = (Id == null) ? new Mix__c() : [SELECT Name, Customer__c FROM Mix__c WHERE Id = :Id];
        if (ApexPages.currentPage().getParameters().get('contactId') != null)
            mix.Customer__c = ApexPages.currentPage().getParameters().get('contactId');
        if (Id != null)
        {
            for (Song__c s : [SELECT Id,Name,Genre__c,Length_m__c FROM Song__c WHERE Id IN
                (SELECT Song__c FROM Track__c WHERE Mix__c = :mix.Id)] )
                selectedSongs.put(s.Id,s);
            getSelectedSong();
            initSummary();
        }
    }

    public PageReference save() {
        List<Track__c> tracks = new List<Track__c>();
        Savepoint sp = Database.setSavepoint();
        try
        {
            upsert(mix);
        }
        catch (System.DMLException e)
        {
            ApexPages.addMessages(e);
            return null;
        }

        for (Song__c s: selectedSongs.values())
            tracks.add(new Track__c(Mix__c = mix.Id, Song__c = s.Id));
        try
        {
            delete([SELECT Id FROM Track__c WHERE Mix__c = :mix.Id]);
            insert tracks;
            selectedSongs = null;
        }
        catch (DmlException e)
        {
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
        }

        PageReference redirectSuccess = new ApexPages.StandardController(Mix).view();
        return (redirectSuccess);
    }

    public PageReference cancel() {
        return Setcon.cancel();
    }

    // Dynamically creates list for genre filter 
    public List<SelectOption> getGenres()
    {
        List<SelectOption> so = new List<SelectOption>();           
        Schema.DescribeFieldResult field = Song__c.Genre__c.getDescribe();
        so.add(new SelectOption('--Any Genre--', '--Any Genre--'));
        for (Schema.PicklistEntry f : field.getPicklistValues())
            so.add(new SelectOption(f.getLabel(), f.getLabel()));
        return so;   
    }

    public List<SongWrapper> getSong()
    {
        getSelectedSong();
        wrappers = new List <SongWrapper>();
        for (Song__c song : (List<Song__c>)Setcon.getRecords())
            if (selectedSongs.ContainsKey(song.id))
                wrappers.add (new SongWrapper(song,true));
            else
                wrappers.add(new SongWrapper(song,false));
        return wrappers;
    }

    public void getSelectedSong()
    {
        if (wrappers != null)
            for (SongWrapper wr : wrappers)
                if (wr.bool == true)
                    selectedSongs.put(wr.song.id, wr.song); // Add the selected song id in to the selectedSongs.
                else
                    selectedSongs.remove(wr.song.id);
    }

    public void filterByGenre()
    {
        if ( !genreToShow.equals('--Any Genre--') )
            query='SELECT Name,Genre__c,Length_m__c FROM Song__c WHERE Genre__c="'+genreToShow+'"';
        else
            query='SELECT Name,Genre__c,Length_m__c FROM Song__c';
        setCon = new ApexPages.StandardSetController(Database.query(String.escapeSingleQuotes(query)));
        setCon.setpagesize(RECORDS_PER_PAGE);
    }

    
    public void firstPage()
    {
        setCon.first();
    }

    public void previousPage()
    {
        setCon.previous();
    }

    public void nextPage()
    {
        setCon.next();
    }

    public void lastPage()
    {
        setCon.last();
    }

    public void recalculateSummary()
    {
        Song__c s = wrappers.get(Integer.valueOf(System.currentPagereference().getParameters().get('wrapperId'))).song;
        if ( !selectedSongs.containsKey(s.Id) )
        {
            selectedSongs.put(s.Id, s);
            trackLength += s.Length_m__c;
            trackCount++;
        }
        else 
        {
            trackLength -= s.Length_m__c;
            trackCount--;
            selectedSongs.remove(s.Id);
        }
    }

    private void initSummary()
    {
        trackLength = 0;
        getSelectedSong();
        trackCount = selectedSongs.size();
        for (Song__c s : selectedSongs.values())
            trackLength += s.Length_m__c;
    }

    @testVisible
    private class SongWrapper
    {
        public Song__c song{get;set;}
        public boolean bool{get;set;}
        public SongWrapper(Song__c s,boolean bool)
            {
                this.song = s;
                this.bool = bool;
            }
    }
}