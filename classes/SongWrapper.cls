@testVisible
public class SongWrapper {
	public Boolean isChosen {get;set;}
	public Song__c song {get; set;}

	public SongWrapper(Song__c song, Boolean isChosen){
		this.song = song;
		this.isChosen = isChosen;
	}
}