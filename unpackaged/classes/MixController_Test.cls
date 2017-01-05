@isTest
public class MixController_Test {

    private static Integer TOTAL_GENRES_NUMBER = 19;
    private static Mix__c mix;
    private static PageReference ref;
    private static MixController ctrl;
    private static Integer totalTracks = 0;
    private static Double totalLength = 0.0;

    @testSetup static void setup()
    {
        TestDataFactory.initializeTest();
    }

    @isTest static void testPassContactInUrl()
    {
        Contact c = [SELECT Id FROM Contact].get(0);
        PageReference reference = new PageReference('/apex/NewMixPage?contactId='+c.Id);
        Test.setCurrentPage(reference);
        MixController controller = new MixController();
        System.assertEquals(c.Id, controller.mix.Customer__c);
    }

    @isTest static void testNewMixPageInitialization()
    {
        PageReference reference = new PageReference('/apex/NewMixPage');
        Test.setCurrentPage(reference);
        MixController controller = new MixController();

        System.assertEquals(19, controller.getGenres().size());
        System.assertEquals([SELECT Count(Id) cnt FROM Song__c].get(0).get('cnt'), controller.setCon.getResultSize());
        System.assertEquals(19, controller.getGenres().size());
        System.assertEquals(2, controller.totalPages);
        System.assertEquals(1, controller.pageNumber);
    }

    @isTest static void testFilterByGenre()
    {
        PageReference reference = new PageReference('/apex/NewMixPage');
        Test.setCurrentPage(reference);
        MixController controller = new MixController();
        String randomGenre = [SELECT Genre__c FROM Song__c].
            get((Integer)Math.mod( Math.round(Math.random() * 1000), MixController.RECORDS_PER_PAGE)).Genre__c;
        controller.genreToShow = randomGenre;
        controller.filterByGenre();
        for(MixController.SongWrapper s : controller.getSong())
            System.assertEquals(randomGenre, s.song.Genre__c);

        controller.genreToShow = '--Any Genre--';
        controller.filterByGenre();
        System.assertEquals(MixController.RECORDS_PER_PAGE, controller.getSong().size());
    }

    @isTest static void testExistingMixEditPageInitialization()
    {
        List<Song__c> generatedSongs = initMix();

        System.assertEquals(mix.Name, ctrl.mix.Name);
        System.assertEquals(mix.Customer__c, ctrl.mix.Customer__c);
        for (Song__c s : generatedSongs)
            System.assert(ctrl.selectedSongs.containsKey(s.Id));

    }

    @isTest static void testPagination()
    {
        List<Song__c> generatedSongs = initMix();
        ctrl.firstPage();
        checkWrapping(true);
        ctrl.lastPage();
        checkWrapping(false);
        ctrl.previousPage();
        checkWrapping(true);
        ctrl.nextPage();
        checkWrapping(false);
    }

    @isTest static void testCancelCommand()
    {
        initMix();
        // API Id has 18 characters, UI Id has 15 characters
        System.assert(('/' + mix.Id).startsWith(ctrl.cancel().getUrl()));
    }

    @isTest static void testSaveCommand()
    {
        PageReference reference = new PageReference('/apex/NewMixPage');
        Test.setCurrentPage(reference);
        MixController controller = new MixController();
        controller.mix.Name = 'newTestMix';
        controller.mix.Customer__c = [SELECT Id FROM Contact].get(0).Id;
        Integer songNumberToGenerate = (Integer)Math.mod( Math.round( Math.random() * 1000 ), MixController.RECORDS_PER_PAGE);
        List<Song__c> songs = [SELECT Id FROM Song__c];
        for (Integer i = 0; i < songNumberToGenerate; i++ )
            controller.selectedSongs.put(songs.get(i).Id , songs.get(i));
        controller.save();

        System.assertEquals(songNumberToGenerate, [SELECT Id FROM Track__c ].size());

    }

    private static List<Song__c> initMix()
    {
        mix = [SELECT Id, Name, Customer__c FROM Mix__c].
        get((Integer)Math.mod( Math.round( Math.random() * 1000 ), TestDataFactory.TEST_MIXES_COUNT));
        TestDataFactory.fillMixWithDifferentSongs(mix);
        ref = new PageReference('/apex/NewMixPage?id='+mix.Id);
        Test.setCurrentPage(ref);
        ctrl = new MixController();

        List<Song__c> generatedSongs = [SELECT Id, Length_m__c FROM Song__c WHERE Id IN (SELECT Song__c FROM Track__c WHERE Mix__c = :mix.Id)];
        for (Song__c s : generatedSongs) 
        {
            totalTracks++;
            totalLength += s.Length_m__c;
        }
        return generatedSongs;

    }

    private static void checkWrapping(Boolean firstPage)
    {
        List<Song__c> songs = firstPage ? [SELECT Id FROM Song__c LIMIT :MixController.RECORDS_PER_PAGE] :
                              [SELECT Id FROM Song__c  OFFSET 10];
        Integer i = 0;
        for (Song__c s : songs)
            System.assertEquals(s.Id, ctrl.getSong().get(i++).song.Id);
    }


}