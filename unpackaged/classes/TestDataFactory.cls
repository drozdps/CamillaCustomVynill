@isTest
public class TestDataFactory{

	public static final Integer TEST_MIXES_COUNT = 5;
	public static final Integer MAX_TRACKS_COUNT = 15;
	public static final Integer TEST_SONG_NUMBER = 18;
	public static final Integer MAX_TRACK_COUNT = 20;
	public static final Integer MAX_MIX_LENGTH = 90;

	public static Mix__c getRandomMix()
	{
		return [SELECT Id, Name, PrimaryGenre__c, SecondaryGenre__c FROM Mix__c].get((Integer)Math.mod(Math.round(Math.random()*1000), TEST_MIXES_COUNT));
	}

	public static void initializeTest()
	{
		Contact testContact = new Contact(LastName = 'testContacts');
		insert testContact;
		List<Mix__c> mixes = new List<Mix__c>();
		for (Integer i = 0; i < TEST_MIXES_COUNT; i++)
			mixes.add(new Mix__c(Name='testMix'+i,Customer__c = testContact.Id,PrimaryGenre__c='',SecondaryGenre__c=''));
		insert mixes;
		List<sObject> ls = Test.loadData(Song__c.sObjectType, 'testSongs');
	}

	public static Mix__c getRandomMix(Mix__c mix)
	{
		Mix__c anotherMix;
		do
		{
			anotherMix = getRandomMix();
		}
		while (mix.Id == anotherMix.Id);
		return anotherMix;
	}

	public static List<Track__c> createRelatedTracks(Mix__c mix, Boolean oneSong)
	{
		List<Track__c> tracks = new List<Track__c>();
		List<Song__c> availableSongs = [SELECT Id, Genre__c,Track_Licenses__c FROM Song__c];
		for (Integer i = 0; i < (oneSong ? availableSongs.get(0).Track_Licenses__c : TEST_SONG_NUMBER);i++)
			tracks.add(new Track__c(Mix__c = mix.Id, Song__c = availableSongs.get(oneSong ? 0 : i).Id));
		insert tracks;
		return tracks;
	}

	public static List<Track__c> fillMix(Mix__c mix)
	{
		Song__c s = new Song__c(Name='song',Track_Licenses__c =22,Length_m__c = 1.00, Artist__c = 'Michael Jackson');
		insert s;
		List<Track__c> tracks = new List<Track__c>();
		for (Integer i = 0; i < MAX_TRACK_COUNT; i++)
			tracks.add(new Track__c(Mix__c = mix.Id, Song__c = s.Id));
		insert tracks;
		return tracks;
	}
	public static List<Track__c> fillMixWithDifferentSongs(Mix__c mix)
	{
		List<Track__c> tracks = new List<Track__c>();
		for(Song__c s : [SELECT Id FROM Song__c])
			tracks.add(new Track__c(Mix__c = mix.Id, Song__c = s.Id));
		insert tracks;
		return tracks;
	}

}