-- Values the server and client must agree on. Server-only settings stay in their own scripts.
return {
	SPAWN_ANCHOR_TIME = 3, -- RoundManager holds players in the air this long; SpawnCountdown counts it
	RANKING_ABBREVIATIONS = {"st", "nd", "rd"}, -- RoundManager boards + RoundResultsUpdate
	SPLEEF_FADE_TIME = 0.6, -- SpleefTiles timing + SpleefTilesClient tween
}
