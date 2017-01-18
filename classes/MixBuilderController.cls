public  class MixBuilderController{
	private static final Integer TRACK_COUNT = 0;
	private static final Double MIX_LENGTH = 0;
	private static final Integer REMAINING_TRACKS = 20;
	private static final Double REMAINING_LENGTH = 90.0;
	@testVisible private static final Integer NUMBER_OF_RECORDS = 5;

	private ApexPages.StandardSetController stdSetController;
	@testVisible private Map <Id, Song__c> tracksPerMix;
	private String query = 'select id,Name,Genre__c,Length_m__c from Song__c';
	@testVisible private List<SongWrapper> wrappedSongs;
	public Mix__c mix {	get; private set;}
	public List<SelectOption> genresPicklist;
	public String genre {get; set;}
	public Integer trackCount {	get; set;}
	public Double mixLength {get;set;}
	public Integer remainingTracks {get; set;}
	public Double remainingMixLength {get;set;}
	public integer pageNumber{
		get{
			return stdSetController.getPageNumber();
		}
		set;
	}
	public Integer totalPages{
		get{
			Integer total = (Integer)(stdSetController.getResultSize() / ((Decimal)NUMBER_OF_RECORDS)).round(
					System.RoundingMode.CEILING);
			return ( total == 0) ? 1 : total;
		}
		set;
	}
	public MixBuilderController(ApexPages.StandardController acon) {
		Id mixId = ApexPages.currentPage().getParameters().get('id');

		stdSetController = new ApexPages.StandardSetController(Database.query(query));

		stdSetController.setpagesize(NUMBER_OF_RECORDS);
		tracksPerMix = new Map <id,Song__c>();

		mix = (mixId == null) ? new Mix__c() : [select id,Name, Customer__c from Mix__c where Id = :mixId];

		for (Song__c s : [select Name,Genre__c,Length_m__c from Song__c where Id in
		                (select Song__c from Track__c where Mix__c =: mixId)] ) {
			tracksPerMix.put(s.Id, s);
		}

		getSongs();
		initializeMixInfo();

		genre = '--Any Genre--';
		genresPicklist = getPicklistValues(new Song__c(), 'Genre__c');
	}

	public List<SelectOption> getGenresPicklist() {
		genresPicklist.add(0, new SelectOption('--Any Genre--', '--Any Genre--'));
		return genresPicklist;
	}

	public void updateMixInfo() {
		for (SongWrapper sw: wrappedSongs) {
			if (sw.isChosen == true && !tracksPerMix.containsKey(sw.song.Id))
			{
				tracksPerMix.put(sw.song.Id, sw.song);
				mixLength += sw.song.Length_m__c;
				remainingMixLength -=sw.song.Length_m__c;
			} else if (sw.isChosen == false && tracksPerMix.containsKey(sw.song.Id))
			{
				tracksPerMix.remove(sw.song.Id);
				mixLength -= sw.song.Length_m__c;
				remainingMixLength+= sw.song.Length_m__c;
			}
		}
		trackCount = tracksPerMix.size();
		remainingTracks = REMAINING_TRACKS - tracksPerMix.size();
	}

	public void initializeMixInfo() {
		getSelectedSongs();
		trackCount = tracksPerMix.size();
		mixLength = MIX_LENGTH;
		remainingTracks = REMAINING_TRACKS - tracksPerMix.size();
		remainingMixLength = REMAINING_LENGTH;
		for (Song__c s: tracksPerMix.values()) {
			mixLength += s.Length_m__c;
			remainingMixLength -= s.Length_m__c;
		}
	}

	private static list<SelectOption> getPicklistValues(SObject obj, String fld) {
		List<SelectOption> options = new list<SelectOption>();
		Schema.sObjectType objType = obj.getSObjectType();
		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
		map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

		List<Schema.PicklistEntry> values =
				fieldMap.get(fld).getDescribe().getPickListValues();

		for (Schema.PicklistEntry a : values) {
			options.add(new SelectOption(a.getLabel(), a.getValue()));
		}
		return options;
	}

	public void getSelectedSongs() {
		if (wrappedSongs != null)
			for (SongWrapper sw : wrappedSongs)
				if (sw.isChosen == true)
					tracksPerMix.put(sw.song.id, sw.song);
				else
					tracksPerMix.remove(sw.song.id);
	}

	public List<SongWrapper> getSongs() {
		getSelectedSongs();
		wrappedSongs = new List <SongWrapper>();
		for (Song__c song : (List<Song__c>)stdSetController.getRecords()) {
			if (tracksPerMix.ContainsKey(song.id)) {
				wrappedSongs.add(new SongWrapper(song, true));
			} else {
				wrappedSongs.add(new SongWrapper(song, false));
			}
		}
		return wrappedSongs;
	}

	public void songsFiltration() {
		if (genre.equals('--Any Genre--')) {
			query = 'select id,Name,Genre__c,Length_m__c from Song__c';
		}
		else {
			query = 'select id,Name,Genre__c,Length_m__c from Song__c where Genre__c=\'' + genre + '\'';
		}
		stdSetController = new ApexPages.StandardSetController(Database.query(query));
		stdSetController.setpagesize(NUMBER_OF_RECORDS);
		pageNumber = stdSetController.getPageNumber();
		totalPages =
		(Integer)(stdSetController.getResultSize() / ((Decimal)NUMBER_OF_RECORDS)).round(System.RoundingMode.CEILING);
	}

	public PageReference save() {

		List<Track__c> tracks = new List<Track__c>();
		try {
			if (this.remainingMixLength > REMAINING_LENGTH) {
				ApexPages.addMessage(
						new ApexPages.Message(ApexPages.Severity.ERROR,'The maximum mix length is 90.0 minutes'));
			} else if (this.trackCount > REMAINING_TRACKS) {
				ApexPages.addMessage(
						new ApexPages.Message(ApexPages.Severity.ERROR,'You can choose no more than 20 tracks.'));
			} else {
				upsert mix;
				delete([select Id from Track__c where Mix__c = :mix.Id]);

				for (Song__c s: tracksPerMix.values()) {
					tracks.add(new Track__c(Mix__c = mix.Id, Song__c = s.id));
				}
				insert tracks;
			}
		} catch (DmlException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
			return null;
		}

		PageReference redirectSuccess = new ApexPages.StandardController(mix).view();
		return redirectSuccess;
	}

	public PageReference cancel() {
		return stdSetController.cancel();
	}

	public void first() {
		stdSetController.first();
	}

	public void previous() {
		stdSetController.previous();
	}

	public void next() {
		stdSetController.next();
	}

	public void last() {
		stdSetController.last();
	}
}