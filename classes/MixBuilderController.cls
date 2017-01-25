public  class MixBuilderController
{
	private static final Integer TRACK_COUNT = 0;
	private static final Integer REMAINING_TRACKS = 20;
	private static final Double MIX_LENGTH = 0;
	private static final Double REMAINING_LENGTH = 90.0;
	@testVisible private static final Integer NUMBER_OF_RECORDS = 5;
	@testVisible private ApexPages.StandardSetController stdSetController;
	@testVisible private Map <Id, Song__c> addedSongs;
	@testVisible private List<SongWrapper> wrappedSongs;
	private String  query;
	public Mix__c mix {get; private set;}
	public String currentGenre {get; set;}
	public Integer trackCount {get; set;}
	public Double mixLength {get;set;}
	public Integer remainingTracks {get; set;}
	public Double remainingMixLength {get;set;}
	public List<SelectOption> genresPicklist
	{
		get
		{
			genresPicklist = Utils.getPicklistValues(new Song__c(), 'Genre__c');
			genresPicklist.add(0,new SelectOption('--Any Genre--', '--Any Genre--'));
			return genresPicklist;
		}
		private set;
	}
	public integer pageNumber
	{
		get
		{
			return stdSetController.getPageNumber();
		}
		set;
	}
	public Integer totalPages
	{
		get
		{
			Integer total = (Integer)(stdSetController.getResultSize() / ((Decimal)NUMBER_OF_RECORDS)).round(
					System.RoundingMode.CEILING);
			return (total == 0) ? 1 : total;
		}
		set;
	}

	public MixBuilderController(ApexPages.StandardController acon)
	{
		Id mixId = ApexPages.currentPage().getParameters().get('id');
		mix = (mixId == null) ? new Mix__c() : (Mix__c)acon.getRecord();

		query = 'select id, Name, Genre__c, Length_m__c from Song__c';
		stdSetController = new ApexPages.StandardSetController(Database.query(query));
		stdSetController.setpagesize(NUMBER_OF_RECORDS);
		addedSongs = new Map <id, Song__c>();
		for (Song__c s	:	[select Name, Genre__c, Length_m__c from Song__c where Id in
			(select Song__c from Track__c where Mix__c =: mixId)])
		{
			addedSongs.put(s.Id, s);
		}
		currentGenre = '--Any Genre--';
		getSongs();
		initializeMixInfo();
	}

	public List<SongWrapper> getSongs()
	{
		getSelectedSongs();
		wrappedSongs = new List <SongWrapper>();
		for (Song__c song : (List<Song__c>)stdSetController.getRecords())
		{
			if (addedSongs.ContainsKey(song.id))
			{
				wrappedSongs.add(new SongWrapper(song, true));
			}
			else
			{
				wrappedSongs.add(new SongWrapper(song, false));
			}
		}
		return wrappedSongs;
	}

	private void getSelectedSongs()
	{
		if (wrappedSongs != null)
		{
			for (SongWrapper sw : wrappedSongs)
			{
				if (sw.isChosen == true)
				{
					addedSongs.put(sw.song.id, sw.song);
				}
				else
				{
					addedSongs.remove(sw.song.id);
				}
			}
		}
	}

	public void initializeMixInfo()
	{
		trackCount = addedSongs.size();
		mixLength = MIX_LENGTH;
		remainingTracks = REMAINING_TRACKS - addedSongs.size();
		remainingMixLength = REMAINING_LENGTH;
		for (Song__c s: addedSongs.values())
		{
			mixLength += s.Length_m__c;
			remainingMixLength -= s.Length_m__c;
		}
	}

	public void filterByGenre()
	{
		if (currentGenre.equals('--Any Genre--'))
		{
			query = 'select id, Name, Genre__c, Length_m__c from Song__c';
		}
		else
		{
			query = 'select id, Name, Genre__c, Length_m__c from Song__c where Genre__c=\'' + currentGenre + '\'';
		}
		stdSetController = new ApexPages.StandardSetController(Database.query(query));
		stdSetController.setpagesize(NUMBER_OF_RECORDS);
		pageNumber = stdSetController.getPageNumber();
		totalPages = (Integer)
				(stdSetController.getResultSize() / ((Decimal)NUMBER_OF_RECORDS)).round(System.RoundingMode.CEILING);
	}

	public void updateMixInfo()
	{
		for (SongWrapper sw: wrappedSongs)
		{
			if (sw.isChosen == true && !addedSongs.containsKey(sw.song.Id))
			{
				addedSongs.put(sw.song.Id, sw.song);
				mixLength += sw.song.Length_m__c;
				remainingMixLength -= sw.song.Length_m__c;
			}
			else if (sw.isChosen == false && addedSongs.containsKey(sw.song.Id))
			{
				addedSongs.remove(sw.song.Id);
				mixLength -= sw.song.Length_m__c;
				remainingMixLength += sw.song.Length_m__c;
			}
		}
		trackCount = addedSongs.size();
		remainingTracks = REMAINING_TRACKS - addedSongs.size();
	}

	public PageReference save()
	{
		List<Track__c> tracks = new List<Track__c>();
		Savepoint sp = Database.setSavepoint();
		try
		{
			if (mixLength > REMAINING_LENGTH)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
										'The maximum mix length is ' + REMAINING_LENGTH + ' minutes'));
				return null;
			}
			else if (trackCount > REMAINING_TRACKS)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
										'You can choose no more than ' + REMAINING_TRACKS + ' tracks.'));
				return null;
			}
			else
			{
				upsert mix;
				delete([select Id from Track__c where Mix__c = :mix.Id]);
				for (Song__c s: addedSongs.values())
				{
					tracks.add(new Track__c(Mix__c = mix.Id, Song__c = s.id));
				}
				insert tracks;
			}
		}
		catch (DmlException e)
		{
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			return null;
		}
		PageReference redirectSuccess = new ApexPages.StandardController(mix).view();
		return redirectSuccess;
	}

	public PageReference cancel()
	{
		return stdSetController.cancel();
	}

	public void first()
	{
		stdSetController.first();
	}

	public void previous()
	{
		stdSetController.previous();
	}

	public void next()
	{
		stdSetController.next();
	}

	public void last()
	{
		stdSetController.last();
	}
}