@isTest
public class TrackTrigger_Test
{
	public static final Integer MIX_COUNT = 25;

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

	@isTest
	static void testDelete_changesTrackCountAndGenres()
	{
		Mix__c mix = [select id,Primary_Genre__c, Secondary_Genre__c from Mix__c].get(0);
		List<Song__c> allSongs = [select id, Genre__c, Track_Licences__c,
				(select id From Song__c.Tracks__r) from Song__c];
		List<Track__c> tracks = new List<Track__c>();
		for (Song__c s: allSongs)
		{
			for (Integer i = 0; i < s.Track_Licences__c; i++)
			{
				tracks.add(new Track__c(Mix__c = mix.id, Song__c = s.id));
			}
		}
		insert tracks;

		Test.startTest();
		delete tracks;
		Test.stopTest();

		mix = [select Id, Primary_Genre__c, Secondary_Genre__c from Mix__c where Id=:mix.Id];
		System.assertEquals(null, mix.Primary_Genre__c);
		System.assertEquals(null, mix.Secondary_Genre__c);
		for (Song__c s: [select Track_Count__c from Song__c])
		{
			System.assertEquals(0, s.Track_Count__c);
		}
	}

	@isTest
	static void testUndelete_changesTrackCountAndGenres()
	{
		Mix__c mix = [select id,Primary_Genre__c, Secondary_Genre__c from Mix__c].get(0);
		List<Song__c> allSongs = [select id, Genre__c, Track_Licences__c,
										(select id From Song__c.Tracks__r) from Song__c];
		List<Track__c> tracks = new List<Track__c>();
		for (Song__c s: allSongs)
		{
			tracks.add(new Track__c(Mix__c = mix.id, Song__c = s.id));
		}
		insert tracks;
		delete tracks;

		Test.startTest();
		undelete tracks;
		Test.stopTest();

		mix = [SELECT Id, Primary_Genre__c, Secondary_Genre__c FROM Mix__c WHERE Id=:mix.Id];
		System.assertEquals('Rock', mix.Primary_Genre__c);
		System.assertEquals('Blues', mix.Secondary_Genre__c);
		for (Song__c s : [SELECT Track_Count__c FROM Song__c])
		{
			System.assertEquals(1, s.Track_Count__c);
		}
	}

	@isTest
	static void testUpdate_changesTrackCountAndGenres()
	{
		Mix__c mix = [select id,Primary_Genre__c, Secondary_Genre__c from Mix__c].get(0);
		List<Song__c> allSongs = [select id, Genre__c, Track_Licences__c,
										(select id From Song__c.Tracks__r) from Song__c];
		List<Track__c> tracks = new List<Track__c>();
		for (Integer i = 0; i < allSongs.get(0).Track_Licences__c; i++)
		{
			tracks.add(new Track__c(Mix__c = mix.Id, Song__c = allSongs.get(0).Id));
		}
		insert tracks;
		Song__c newSong = new Song__c(Name = 'testSong', Genre__c = 'Rock', Track_Licences__c = 21, Track_Count__c = 0,
									Length_m__c = 3.19,	Artist__c = 'BMTH');
		insert newSong;
		tracks.get(0).Song__c = newSong.id;

		Test.startTest();
		update tracks.get(0);
		Test.stopTest();

		mix = [select Id, Primary_Genre__c, Secondary_Genre__c from Mix__c where Id=:mix.Id].get(0);
		newSong = [select Track_Count__c from Song__c where Id=:newSong.Id].get(0);
		System.assertEquals('Blues', mix.Primary_Genre__c);
		System.assertEquals('Rock', mix.Secondary_Genre__c);
		System.assertEquals(1, newSong.Track_Count__c);
	}

	@isTest
	static void testUpdate_checkErrors()
	{
		Mix__c mix = [select id, Primary_Genre__c, Secondary_Genre__c from Mix__c].get(0);
		Song__c song = [select id, Genre__c, Track_Licences__c,
						(select id From Song__c.Tracks__r) from Song__c].get(0);
		List<Track__c> tracks = new List<Track__c>();
		for (Integer i = 0; i < song.Track_Licences__c; i++)
		{
			tracks.add(new Track__c(Mix__c = mix.Id, Song__c = song.Id));
		}
		insert tracks;
		Song__c newSong =
				new Song__c(Name = 'testSong', Genre__c = 'Rock', Track_Licences__c = song.Track_Licences__c,
							Track_Count__c = 0, Length_m__c = 3.19, Artist__c = 'testArt');
		insert newSong;
		for (Track__c t: tracks)
		{
			t.Song__c = newSong.id;
		}

		Test.startTest();
		List<Database.SaveResult> sResult = Database.update(tracks, false);
		Test.stopTest();
		System.assertEquals(false, sResult.get(tracks.size() - 1).isSuccess());
	}

	@isTest
	static void testInsert()
	{
		List<Track__c> trackList = new List<Track__c>();
		List<Song__c> songs = [select id from Song__c];
		List<Mix__c> mixes = [select id from Mix__c];
		for (Song__c s: songs)
		{
			trackList.add(new Track__c(Mix__c = mixes.get(0).id, Song__c = s.id));
		}

		Test.startTest();
		insert trackList;
		Test.stopTest();

		songs = [select Track_Count__c, Genre__c from Song__c];
		Mix__c mix = [select Primary_Genre__c, Secondary_Genre__c from Mix__c where id=: mixes.get(0).id].get(0);
		for (Song__c s: songs)
		{
			System.assertEquals(1, s.Track_Count__c);
		}
		System.assertEquals('Rock', mix.Primary_Genre__c);
		System.assertEquals('Blues', mix.Secondary_Genre__c);
	}

	@isTest static void testInsert_checkErrors()
	{
		List<Track__c> tracks = new List<Track__c>();
		Song__c song = new Song__c(Name = 'testSong', Genre__c = 'Rock', Track_Licences__c = 11, Track_Count__c = 0,
									Length_m__c = 3.19,	Artist__c = 'testArt');
		insert song;
		Mix__c mix = [select id from Mix__c].get(0);

		//amount of tracks is more than amount of licenses
		for (Integer i = 0; i < song.Track_Licences__c; i++)
		{
			tracks.add(new Track__c(Mix__c = mix.id, Song__c = song.id));
		}
		Test.startTest();
		List<Database.SaveResult> sResult = Database.insert(tracks, false);
		Test.stopTest();
		System.assertEquals(false, sResult.get(sResult.size() - 1).isSuccess());
	}
}