/**
 * Created by user on 21.12.2016.
 */
public class TrackTriggerHandler {
	public static void calculateTracks(Set<id> songs) {

		List<Song__c> songList = [
				select Id, Name, Track_Count__c, (select id From Song__c.Tracks__r)
				from Song__c
				where id IN:songs
		];
		for (Song__c song: songList) {
			song.Track_Count__c = song.Tracks__r.size();
		}
		update songList;
	}

	public static void defineGenre(Set<id> mixes, List<Track__c> tracks) {

		List<AggregateResult> groupedResult = [
				select Track__c.Song__r.Genre__c genre, Mix__c mix
				from Track__c
				where Track__c.Mix__c in: mixes
		        group by Mix__c,Track__c.Song__r.Genre__c
		        order by COUNT(Track__c.Song__r.Genre__c) DESC
		];

		List<MIx__c> mixesToUpsert = findMixesToUpsert(groupedResult);

		upsert mixesToUpsert;
	}

	public static List<Mix__c> findMixesToUpsert(List<AggregateResult> groupedResult) {
		Id mId = (Id)groupedResult.get(0).get('mix');
		List<MIx__c> mixesToUpsert = new List<MIx__c>();
		Map<Id, List<String>> mixList = new Map<Id, List<String>>();

		mixList.put(mId, new List<String>());
		mixList.get(mId).add((String)groupedResult.get(0).get('genre'));

		mixesToUpsert.add(new Mix__c(Id = mId, Primary_Genre__c = mixList.get(mId).get(0)));

		for (Integer i = 1; i < groupedResult.size(); i++) {
			mId = (Id)groupedResult.get(i).get('mix');
			if (mixList.containsKey(mId) && mixList.get(mId).size() == 1) {
				mixList.get(mId).add((String)groupedResult.get(i).get('genre'));
				mixesToUpsert.get(mixesToUpsert.size() - 1).Secondary_Genre__c = mixList.get(mId).get(1);
			} else if (!mixList.containsKey(mId)) {
				mixList.put(mId, new List<String>());
				mixList.get(mId).add((String)groupedResult.get(i).get('genre'));
				mixesToUpsert.add(new Mix__c(Id = mId, Primary_Genre__c = mixList.get(mId).get(0)));
			}
		}
		return  mixesToUpsert;
	}
}