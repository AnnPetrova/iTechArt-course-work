@isTest
public class MixBuilderController_Test
{
	private static final Integer MIX_COUNT = 15;
	private static Mix__c mix;
	private static PageReference pageReference;
	private static MixBuilderController mixController;

	@testSetup static void setup()
	{
		List<Mix__c> mixes = new List<Mix__c>();
		Contact contact = new Contact(LastName = 'testContact');
		insert contact;
		for (Integer i = 0; i < MIX_COUNT; i++)
		{
			mixes.add(new Mix__c(Name = 'test' + i, Customer__c = contact.Id, Primary_Genre__c = null,
					Secondary_Genre__c = null));
		}
		insert mixes;
		List<sObject> ls = Test.loadData(Song__c.sObjectType, 'songsResourse');
	}

	@isTest static void testCancel()
	{
		mix = [select id, Name, Customer__c from Mix__c].get(0);
		List<Track__c> tracks = createTracksForMix();
		pageReference = new PageReference('/apex/MixBuilder?id=' + mix.id);
		Test.setCurrentPage(pageReference);
		mixController = new MixBuilderController(new ApexPages.StandardController(mix));

		System.assert(('/' + mix.Id).startsWith(mixController.cancel().getUrl()));
	}

	private static List<Track__c> createTracksForMix()
	{
		List<Track__c> tracks = new List<Track__c>();
		for (Song__c s : [select Id from Song__c])
		{
			tracks.add(new Track__c(Mix__c = mix.Id, Song__c = s.Id));
		}
		insert tracks;
		return tracks;
	}

	@isTest static void testSave()
	{
		initPage();
		List<Song__c> songs = [SELECT Id FROM Song__c];
		for (Integer i = 0; i < 4; i++)
		{
			mixController.addedSongs.put(songs.get(i).id, songs.get(i));
		}
		mixController.save();
		List<Track__c> tracks = [select id from Track__c];

		//check if the amount of saved songs equals to the amount of selected
		System.assertEquals(4, tracks.size());
	}

	@isTest static void testSongsFiltration()
	{
		initPage();
		String genreToTest = '--Any Genre--';
		mixController.currentGenre = genreToTest;
		mixController.filterByGenre();
		System.assertEquals(MixBuilderController.NUMBER_OF_RECORDS, mixController.getSongs().size());

		mixController.currentGenre = 'Rock';
		mixController.filterByGenre();
		for (SongWrapper sw: mixController.getSongs())
		{
			System.assertEquals('Rock', sw.song.Genre__c);
		}
	}

	@isTest static void testUpdatingMixInfo()
	{
		initPage();
		mixController.initializeMixInfo();
		List<Song__c> songs = [SELECT Id, Length_m__c FROM Song__c];
		mixController.wrappedSongs.add(new SongWrapper(songs.get(0), true));
		mixController.updateMixInfo();

		System.assertEquals(1, mixController.trackCount);
		System.assertEquals(songs.get(0).Length_m__c, mixController.mixLength);
		System.assertEquals(19, mixController.remainingTracks);
		System.assertEquals(90 - songs.get(0).Length_m__c, mixController.remainingMixLength);
	}

	@isTest static void testPagination()
	{
		initPage();
		mixController.first();
		List<Song__c> songs = [select id from Song__c limit: MixBuilderController.NUMBER_OF_RECORDS];
		for (Integer i = 0; i < songs.size(); i++)
		{
			System.assertEquals(songs.get(i).id, mixController.wrappedSongs.get(i).song.id);
		}
		mixController.next();
		checkSongsFromPage();
		System.assertEquals(2, mixController.pageNumber);
		System.assertEquals(3, mixController.totalPages);

		mixController.last();
		System.assertEquals(3, mixController.pageNumber);
		System.assertEquals(3, mixController.totalPages);

		mixController.previous();
		checkSongsFromPage();
		System.assertEquals(2, mixController.pageNumber);
		System.assertEquals(3, mixController.totalPages);
	}

	private static void initPage()
	{
		pageReference = new PageReference('/apex/MixBuilder');
		Test.setCurrentPage(pageReference);
		mix = new Mix__c();
		mixController = new MixBuilderController(new ApexPages.StandardController(mix));
		mixController.mix.Name = 'testMix';
		mixController.mix.Customer__c = [select id from Contact].get(0).id;
	}

	private static void checkSongsFromPage()
	{
		List<Song__c> songs = [select id from Song__c limit 5 offset: 5];
		for (Integer i = 0; i < songs.size(); i++)
		{
			System.assertEquals(songs.get(i).id, mixController.getSongs().get(i).song.id);
		}
	}
}