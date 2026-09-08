class_name GameRules
extends RefCounted
## Identity/limits only. No combat, recruitment, or progression system in M0.

const CONTENT_VERSION: String = "m0.1"
const MAIN_WEAPON_SLOTS: int = 1
const SHIELD_SLOTS: int = 1
const MAX_SUPPORTS: int = 5
const STARTING_RANK: int = 1
const MAX_RANK: int = 8
enum SupportFamily { ARC_AERIAL, BASS_DRIVER, STATIC_NET, ECHO_DECK, NEEDLE_SWARM, REVERB_WELL }
