#!/usr/bin/env python3

import requests
import urllib
import json
import os #for downloading function
from bs4 import BeautifulSoup

client_access_token = "B0ji-zXRGhBl2VQezJGpDVXJAarPyAelHOpAVHw0a4NBthn7XU-wJiCf-lvBwLON"

def searchGenius(search_term):	
	# Format a request URI for the Genius API
	_URL_API = "https://api.genius.com/"
	_URL_SEARCH = "search?q="
	querystring = _URL_API + _URL_SEARCH + urllib.request.quote(search_term)

	request = urllib.request.Request(querystring)
	request.add_header("Authorization", "Bearer " + client_access_token)
	request.add_header("User-Agent", "")

	response = urllib.request.urlopen(request, timeout=3)
	string = response.read().decode('utf-8')
	json_obj = json.loads(string)

	search_results = json_obj['response']['hits'][:]

	return search_results

#------ TXT FILE DOWNLOADING -------
def getListFromTxt(filename):
	try:
		text_file = open(filename, "r")
		rappers = text_file.read().split('\n')
		text_file.close()
		rappers = list(filter(None, rappers)) # remove blank entries
		return rappers

	except FileNotFoundError:
		print("File not found.")
		exit()

def scrapeLyricsForArtistsInList(artist_names_list):
	for artist_name in artist_names_list:
		print("Scraping lyrics for", artist_name, "...")
		scrapeLyricsForArtist(artist_name)
		print("==========")
	print("Done!")

def scrapeLyricsForArtist(search_term):
	search_results = searchGenius(search_term) #search results for search term
	artists = createArtistDict(search_results) #dict of 1 artist holding their songs + lyrics
	makeArtistDirWithSongs(artists) #adds dir with artistname and songs inside of master dir

def createArtistDict(search_results):
	#print("Scraping lyrics...")
	artists = {new_list: [] for new_list in range(0)}
	artist_count = 0

	for item in search_results:
		artist_name = item['result']['primary_artist']['name']
		song_name = item['result']['title'].encode('ascii', 'ignore').decode("utf-8")
		song_name = song_name.replace('/', '')
		URL = item['result']['url']

		#Scrape page for lyrics
		page = requests.get(URL)
		html = BeautifulSoup(page.text, "html.parser") #extracts html as string
		lyrics = html.find("div", class_="lyrics").get_text()

		#if this is the first search result
		if artist_count == 0:
			artists[artist_name] = {song_name : lyrics}
			artist_count += 1
		#artist already exists, append to them
		elif artist_name in artists.keys():
			artists[artist_name][song_name] = lyrics

	# dictionary containing 1 artist, which is a dict containing a dict of song and lyrics
	return artists

def makeArtistDirWithSongs(artists):
	artist_name = [artist for artist in artists]
	artist_name = artist_name[0]
	artist_dir = "./" + artist_name
	#create dir named $artist_name inside of $artist_dir
	if not os.path.exists(artist_dir):
		os.makedirs(artist_dir)

	for artist in artists:
		for song in artists[artist]:
			f = open(artist_dir + "/" + song + ".txt", "w+")
			f.write(artists[artist][song])
			f.close()
			print("Created", artist_dir + "/" + song + ".txt")

#--------------------------------

def manuallyGetLyrics(option):
	cont = True
	while cont:
		search_term = input("Search Genius for something: ")
		search_results = searchGenius(search_term)
		artists = generateArtistsForManualChoosing(search_results)
		print("Pick an artist: ")
		artists_list = [artist for artist in artists]
		for i, artist in enumerate(artists_list):
			print("(",i,")", artist)

		try:
			artist_name = artists_list[int(input("#"))]
		except (IndexError, ValueError):
			print("Invalid option.")
			continue

		if option == "download":
			artist_dir = "./" + artist_name
			#create dir named $artist_name inside of $artist_dir
			if not os.path.exists(artist_dir):
				os.makedirs(artist_dir)
				#os.mkdir(artist_dir)

			for artist in artists:
				for song in artists[artist]:
					f = open(artist_dir + "/" + song + ".txt", "w+")
					f.write(artists[artist][song])
					f.close()
					print("Created", artist_dir + "/" + song + ".txt")

		elif option == "view":
			print("Pick a song: ")
			songs_list = [song for song in artists[artist_name]]
			for i, song in enumerate(songs_list):
				print("(",i,")", song)

			try:
				song_name = songs_list[int(input("#"))]
			except (IndexError, ValueError):
				print("Invalid option.")
				continue
			
			print("==============")
			print("Lyrics for", song_name, "by", artist_name)
			print("==============")
			
			print(artists[artist_name][song_name])

		cont = (input("Continue? (y/n) ") == "y")

def generateArtistsForManualChoosing(search_results):
	print("Scraping lyrics...")
	artists = {new_list: [] for new_list in range(0)}

	for item in search_results:
		artist_name = item['result']['primary_artist']['name']
		song_name = item['result']['title'].encode('ascii', 'ignore').decode("utf-8")
		song_name = song_name.replace('/', '')
		URL = item['result']['url']

		#Scrape page for lyrics
		page = requests.get(URL)
		html = BeautifulSoup(page.text, "html.parser") #extracts html as string
		lyrics = html.find("div", class_="lyrics").get_text()

		if artist_name not in artists.keys():
			artists[artist_name] = {song_name : lyrics}
		else:
			artists[artist_name][song_name] = lyrics

	return artists

#-----------
try:
	print("==========")
	print("Hello friend, welcome to the Lyric Viewer/Downloader Interface")
	print("This data is brought to you by the Genius API")
	print("==========")
	print("(1) Browse Lyrics")
	print("(2) Download Lyrics")
	choice = input()
	print("==========")

	if choice == "1":
		manuallyGetLyrics("view")

	elif choice == "2":
		print("Input Artist via: ")
		print("(1) Keyboard")
		print("(2) TXT File (newline separated entries)")

		choice = input()
		if choice == "1":
			manuallyGetLyrics("download")
		elif choice == "2":
			filename = input("Enter name of .txt file: ")
			rappers = getListFromTxt(filename)
			scrapeLyricsForArtistsInList(rappers)
		else:
			print("Invalid choice.")
			exit()	
	else:
		print("Invalid choice.")
		exit()	

except KeyboardInterrupt:
		print("\nGoodbye!")
		exit()
