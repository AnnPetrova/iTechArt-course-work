/**
 * Created by user on 05.01.2017.
 */
public class Song {
	public Boolean isChosen {get;set;}
	public Song__c song {get; set;}

	public Song(Song__c song, Boolean isChosen){
		this.song = song;
		this.isChosen = isChosen;
	}
}