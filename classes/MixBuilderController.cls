public with sharing class MixBuilderController{
	public ApexPages.StandardController stdController {
		get; set;
	}

	public Mix__c mix {
		get; private set;
	}
	public List<Track__c> tracksPerMix {
		get; private set;
	}
	public List<Song> songs {
		get; private set;
	}
	public String genre {
		get; set;
	}

	public List<SelectOption> genres;

	public Integer trackCount {
		get; set;
	}
	public Double mixLength {
		get; set;
	}
	public Integer remainingTracks {
		get; set;
	}
	public Double remainingMixLength {
		get; set;
	}

	public String listId {
		get;set;
	}

	public MixBuilderController(ApexPages.StandardController acon) {
		stdController = acon;
		Id mixId = ApexPages.currentPage().getParameters().get('id');


		this.mix = (mixId == null) ? new Mix__c() : [SELECT id,Name, Customer__c FROM Mix__c WHERE Id = :mixId];
		this.tracksPerMix = [select Mix__c, Song__c from Track__c where Mix__c =: mix.Id];

		this.songs = getSelectedSongs();

		if(!tracksPerMix.isEmpty()){
			for(Song s: songs)
				for(Track__c t: tracksPerMix){
					if(s.song.id==t.Song__c){
						s.isChosen = true;
					}
				}
		}

		this.remainingMixLength = 90.0;
		this.remainingTracks = 20;
		this.mixLength = 0.0;
		this.trackCount = tracksPerMix.size();
		this.remainingTracks = 20 - tracksPerMix.size();

		this.trackCount = tracksPerMix.size();
		for (Song s: songs) {
			this.mixLength += s.song.Length_m__c;
			this.remainingMixLength -= s.song.Length_m__c;
		}

		this.genres = getPicklistValues(new Song__c(), 'Genre__c');
	}


	public List<SelectOption> getGenres() {
		this.genres.sort();
		this.genres.add(0, new SelectOption('--Any Genre--', '--Any Genre--'));
		return this.genres;
	}

	public static list<SelectOption> getPicklistValues(SObject obj, String fld) {
		List<SelectOption> options = new list<SelectOption>();
		Schema.sObjectType objType = obj.getSObjectType();
		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
		map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

		List<Schema.PicklistEntry> values =
				fieldMap.get(fld).getDescribe().getPickListValues();

		for (Schema.PicklistEntry a : values)
			{
				options.add(new SelectOption(a.getLabel(), a.getValue()));
			}
		return options;
	}

	private static List<Song> getSelectedSongs(){
		List<Song> songsToSelect = new List<Song>();
		List<Song__c> allSongs = [select Name, Genre__c, Length_m__c from Song__c];

		for(Song__c song: allSongs){
			songsToSelect.add(new Song(song, false));
		}
		return songsToSelect;
	}

	public PageReference save() {
		try
		{
			upsert(mix);

			for (Song s: this.songs) {
				if(s.isChosen) {
					tracksPerMix.add(new Track__c(Mix__c = mix.Id, Song__c = s.song.id));
				}
			}
			upsert(tracksPerMix);

		} catch (System.DMLException e)
		{
			ApexPages.addMessages(e);
			return null;
		}

		PageReference redirectSuccess = new ApexPages.StandardController(mix).view();
		return redirectSuccess;
	}

	public PageReference cancel() {
		PageReference redirectSuccess = new ApexPages.StandardController(mix).view();
		return (redirectSuccess);
	}
}