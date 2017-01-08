/**
 * Created by user on 23.12.2016.
 */
@isTest
public class TrackUpdateTrigger_Test {
	@isTest
	public static void testInsert()
		{
			List<Track__c> trackList = new List<Track__c>();
			List<Song__c> songs = new List<Song__c>();

			for (Integer i = 0; i < 6; i++) {
				songs.add(new Song__c(Name = 'TestSong' + i, Artist__c = 'BMTH', Length_m__c = 3.14, Track_Count__c = 0,
						Track_Licences__c = 20));
			}
			insert songs;

			List<Mix__c> mixes = new List<Mix__c>();
			for (Integer i = 0; i < 3; i++) {
				mixes.add(new Mix__c());
			}
			insert mixes;

			Test.startTest();

			for (Integer i = 0; i < 50; i++) {
				if (i < 5) {
					trackList.add(new Track__c(Mix__c = mixes.get(0).id, Song__c = songs.get(0).id));
				} else if (i >= 5 && i < 13) {
					trackList.add(new Track__c(Mix__c = mixes.get(0).id, Song__c = songs.get(1).id));
				} else if (i >= 13 && i < 20) {
					trackList.add(new Track__c(Mix__c = mixes.get(0).id, Song__c = songs.get(2).id));
				} else if (i >= 20 && i < 29) {
					trackList.add(new Track__c(Mix__c = mixes.get(1).id, Song__c = songs.get(3).id));
				} else if (i >= 29 && i < 33) {
					trackList.add(new Track__c(Mix__c = mixes.get(1).id, Song__c = songs.get(4).id));
				} else if (i >= 33 && i < 50) {
					trackList.add(new Track__c(Mix__c = mixes.get(2).id, Song__c = songs.get(5).id));
				}
			}
			insert trackList;
			Test.stopTest();

			List<Song__c> testSongs = [select Name, Track_Count__c from Song__c];
			for (Song__c song: testSongs) {
				if (song.id == songs.get(0).id) {
					System.assertEquals(song.Track_Count__c, 5);
				} else if (song.id == songs.get(1).id) {
					System.assertEquals(song.Track_Count__c, 8);
				} else if (song.id == songs.get(2).id) {
					System.assertEquals(song.Track_Count__c, 7);
				} else if (song.id == songs.get(3).id) {
					System.assertEquals(song.Track_Count__c, 9);
				} else if (song.id == songs.get(4).id) {
					System.assertEquals(song.Track_Count__c, 4);
				} else if (song.id == songs.get(5).id) {
					System.assertEquals(song.Track_Count__c, 17);
				}
			}
		}

	@isTest
	public static void testUpdate() {

//		List<String> names = new List<String>();
//		names.add('Run');
//		names.add('Carry on');
//		names.add('Doomed');
//		names.add('Drown');
//		names.add('Happy Song');
//		names.add('Deathbeds');
//		List<Integer> tracks = new List<Integer>();
//		tracks.add(22);
//		tracks.add(23);
//		tracks.add(24);
//		List<Track__c> tracksToUpdate = [select id, Song__c from Track__c where id IN: tracks];
//		tracksToUpdate.get(0).Song__c = tracksToUpdate.get(1).Song__c;
//
//		Test.startTest();
//
//		update tracksToUpdate;
//
//		Test.stopTest();
//
//		Song__c song1 = [select id, Track_Count__c from Song__c where id =: tracksToUpdate.get(0).Song__c];
//		Song__c song2 = [select id, Track_Count__c from Song__c where id =: tracksToUpdate.get(1).Song__c];
//
//				System.assertEquals(song1.Track_Count__c, 3);
//
//				System.assertEquals(song2.Track_Count__c, 8);

	}
}