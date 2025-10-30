#!/usr/bin/env python3
"""
Flask Music Scanner API - Using EXACT Logic from Working Standalone Version
AI-powered sheet music scanner optimized for accuracy over complexity
"""

import base64
import json
import requests
import time
import os
import sys
from PIL import Image
import io
from typing import List, Dict, Optional, Tuple
import re
from dataclasses import dataclass, asdict
import isodate
import urllib.parse

# Flask imports
from flask import Flask, request, jsonify
from flask_cors import CORS

# Configuration - UPDATE THESE WITH YOUR API KEYS
GOOGLE_VISION_API_KEY = ""
GROQ_API_KEY = ""
YOUTUBE_API_KEYS = [
    "",
]

# Supported instruments list
SUPPORTED_INSTRUMENTS = [
    "alto saxophone", "baritone saxophone", "tenor saxophone", "soprano saxophone",
    "bass clarinet", "clarinet", "bassoon", "contrabassoon", 
    "cello", "double bass", "viola", "violin",
    "euphonium", "tuba", "trombone", "trumpet", "french horn",
    "flute", "piccolo", "oboe", "english horn",
    "piano", "harp", "percussion", "timpani",
    "guitar", "electric guitar", "bass guitar"
]

# EXACT SAME DATA STRUCTURES AS WORKING STANDALONE VERSION
@dataclass
class PieceIdentification:
    title: str
    composer: str
    scene_movement: str
    confidence: str
    reasoning: str

@dataclass
class VideoResult:
    video_id: str
    title: str
    channel: str
    video_url: str
    views: int
    likes: int
    duration: str
    duration_seconds: int
    search_strategy: str
    title_match_score: float
    composer_match_score: float
    scene_match_score: float
    duration_match_score: float
    overall_accuracy_score: float

class AccurateMusicScannerAPI:
    """EXACT SAME CLASS AS STANDALONE VERSION - Just adapted for Flask"""
    def __init__(self):
        self.current_youtube_key_index = 0
    
    def create_error_response(self, error_message: str) -> dict:
        """Create standardized error response"""
        return {
            "piece_identification": {
                "title": "",
                "composer": "",
                "scene_movement": "",
                "confidence": "low",
                "reasoning": error_message
            },
            "videos": []
        }
    
    def validate_instrument(self, instrument: str) -> str:
        """Validate and normalize instrument name"""
        if not instrument:
            return "clarinet"  # Default fallback
        
        instrument_lower = instrument.lower().strip()
        
        # Check if instrument is in supported list
        if instrument_lower in SUPPORTED_INSTRUMENTS:
            return instrument_lower
        
        # Try to find partial matches for common variations
        for supported in SUPPORTED_INSTRUMENTS:
            if instrument_lower in supported or supported in instrument_lower:
                return supported
        
        # If no match found, use as-is but log it
        print(f"⚠️ Instrument '{instrument}' not in supported list, using anyway")
        return instrument_lower
    
    def scan_music_from_base64(self, image_data_b64: str, target_instrument: str = "clarinet") -> dict:
        """Complete scanning function - ADAPTED from standalone version for base64 input"""
        try:
            # Validate and normalize instrument
            validated_instrument = self.validate_instrument(target_instrument)
            print(f"🎺 Scanning for instrument: {validated_instrument}")
            print("🎯 Using simplified accuracy-focused approach")
            
            # Step 1: Extract text from base64 image
            print("📸 Extracting text from image...")
            extracted_text = self.extract_text_from_base64(image_data_b64)
            
            if not extracted_text or len(extracted_text.strip()) < 5:
                return self.create_error_response("No readable text found in image")
            
            print(f"✅ Text extracted: {len(extracted_text)} characters")
            print(f"📝 Preview: {extracted_text[:150]}...")
            
            # Step 2: Simple identification - just title, composer, scene
            print("🔍 Identifying piece (title, composer, scene only)...")
            piece_id = self.identify_piece_simple(extracted_text)
            
            if piece_id.confidence.lower() == 'low':
                return self.create_error_response(piece_id.reasoning)
            
            print(f"✅ Identified: '{piece_id.title}' by {piece_id.composer}")
            if piece_id.scene_movement:
                print(f"   Scene/Movement: {piece_id.scene_movement}")
            
            # Step 3: Create simple focused search terms
            print("🔍 Creating focused search terms...")
            search_terms = self.create_simple_search_terms(piece_id, validated_instrument)
            
            # Step 4: Search YouTube
            print("📺 Searching YouTube...")
            videos = self.search_youtube_simple(search_terms)
            
            if not videos:
                return self.create_error_response("No videos found on YouTube - try checking your internet connection")
            
            # Step 5: Rank by accuracy with scene prioritization
            print("🎯 Ranking by accuracy (prioritizing scene matches)...")
            ranked_videos = self.rank_by_accuracy(videos, piece_id, validated_instrument)
            
            # Get top 5 videos - prefer high accuracy but always return up to 5 if available
            high_accuracy_videos = [v for v in ranked_videos if v.overall_accuracy_score >= 6.0]
            
            if len(high_accuracy_videos) >= 5:
                # We have enough high-accuracy videos
                selected_videos = high_accuracy_videos[:5]
            else:
                # Take all high-accuracy videos plus fill remainder with best available
                selected_videos = ranked_videos[:5]  # Just take top 5 regardless of score
            
            result = {
                "piece_identification": {
                    "title": piece_id.title,
                    "composer": piece_id.composer,
                    "scene_movement": piece_id.scene_movement,
                    "confidence": piece_id.confidence,
                    "reasoning": piece_id.reasoning
                },
                "videos": [
                    {
                        "id": video.video_id,
                        "title": video.title,
                        "channel": video.channel,
                        "url": video.video_url,
                        "views": video.views,
                        "likes": video.likes,
                        "duration": video.duration,
                        "duration_seconds": video.duration_seconds,
                        "search_strategy": video.search_strategy,
                        "title_match_score": video.title_match_score,
                        "composer_match_score": video.composer_match_score,
                        "scene_match_score": video.scene_match_score,
                        "duration_match_score": video.duration_match_score,
                        "overall_accuracy_score": video.overall_accuracy_score
                    }
                    for video in selected_videos
                ]
            }
            
            scene_matches = sum(1 for v in result['videos'] if v['scene_match_score'] >= 8.0)
            high_accuracy_count = sum(1 for v in result['videos'] if v['overall_accuracy_score'] >= 6.0)
            print(f"✅ Found {len(result['videos'])} videos ({high_accuracy_count} high accuracy, {scene_matches} with scene matches)")
            return result
            
        except Exception as e:
            error_msg = f"Scan failed: {str(e)}"
            print(f"❌ {error_msg}")
            return self.create_error_response(error_msg)
    
    def extract_text_from_base64(self, base64_image: str) -> str:
        """Extract text from base64 image using Google Vision API"""
        # Optimize image first
        try:
            # Decode base64 to image
            image_data = base64.b64decode(base64_image)
            image = Image.open(io.BytesIO(image_data))
            
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            if image.size[0] > 1024 or image.size[1] > 1024:
                image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
            
            buffer = io.BytesIO()
            image.save(buffer, format='JPEG', quality=85)
            optimized_data = buffer.getvalue()
            optimized_b64 = base64.b64encode(optimized_data).decode('utf-8')
        except Exception as e:
            # If optimization fails, use original
            optimized_b64 = base64_image
        
        # Call Vision API
        url = f"https://vision.googleapis.com/v1/images:annotate?key={GOOGLE_VISION_API_KEY}"
        
        payload = {
            "requests": [
                {
                    "image": {"content": optimized_b64},
                    "features": [{"type": "TEXT_DETECTION", "maxResults": 1}]
                }
            ]
        }
        
        response = requests.post(url, json=payload, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        responses = data.get('responses', [])
        
        if not responses:
            raise Exception("No response from Vision API")
        
        first_response = responses[0]
        
        if 'error' in first_response:
            raise Exception(f"Vision API error: {first_response['error']}")
        
        text_annotations = first_response.get('textAnnotations', [])
        if not text_annotations:
            raise Exception("No text found in image")
        
        return text_annotations[0].get('description', '')
    
    def identify_piece_simple(self, extracted_text: str) -> PieceIdentification:
        """UPDATED METHOD - More permissive, encourages educated guesses, but errors if composer is Unknown"""
        url = "https://api.groq.com/openai/v1/chat/completions"
        
        prompt = f"""Analyze this sheet music text to identify the essential information. Even if unclear, make educated guesses based on what you can see:

EXTRACTED TEXT:
{extracted_text}

I need you to identify:
1. **Title** - The name of the piece (be precise, include subtitles if present)
2. **Composer** - The composer's name (last name only is perfectly fine)
3. **Scene/Movement** - Any specific movement, scene, act, or section (if present)

IMPORTANT RULES:
- **Make educated guesses even if text is unclear or ambiguous**
- **You MUST be able to identify a composer - if you truly cannot, return "Unknown" and explain why**
- **Only set confidence to "low" if the text makes absolutely no musical sense or appears to be completely unrelated to sheet music**
- Even partial information is valuable - if you can identify either a title OR composer (even with uncertainty), proceed with medium confidence
- Composer last names are totally acceptable (e.g., "Messager", "Brahms", "Mozart")
- Many pieces don't have scene/movement information - this is completely normal
- If you see musical terms, instrument names, or anything that suggests this is sheet music, try to extract whatever title/composer info you can find
- Don't include generic terms like "for orchestra" or instrument names in the title unless they're clearly part of the actual piece title

CONFIDENCE LEVELS:
- **HIGH**: Clear title and composer, may or may not have scene/movement
- **MEDIUM**: Can identify at least a title OR composer with reasonable confidence, even if some ambiguity exists
- **LOW**: Only use this if the text appears to be completely unrelated to music (e.g., random text, technical manuals, etc.) or makes absolutely no sense

Examples of what should get MEDIUM or HIGH confidence (not LOW):
- "Solo de concours", Composer: "Messager" → HIGH
- Partial text showing "...Brahms...Intermezzo..." → MEDIUM (make educated guess about title)
- "Concerto in D" with no clear composer but musical context → set composer to "Unknown" and explain
- Text mentioning "Mozart" and some piece fragments → MEDIUM (make best guess at title)
- "Étude" with partial composer name visible → MEDIUM (extract what you can)

Examples that should get LOW confidence:
- Random computer code or technical documentation
- Grocery lists or completely non-musical text
- Text that makes absolutely no sense in any context

STRATEGY: Be optimistic and make reasonable guesses. Musicians often work with incomplete or unclear sheet music, so help them by extracting whatever useful information you can find, even if imperfect.

Return your response in this JSON format:
{{
    "title": "exact piece title or best guess based on available text",
    "composer": "composer name (last name is fine) or 'Unknown' if truly cannot identify",
    "scene_movement": "specific scene/movement if clearly visible, empty string if not",
    "confidence": "high/medium/low",
    "reasoning": "brief explanation of what you found and why you chose this confidence level"
}}"""

        payload = {
            "model": "llama-3.3-70b-versatile",
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 300,
            "temperature": 0.1
        }
        
        headers = {
            'Authorization': f'Bearer {GROQ_API_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        content = data['choices'][0]['message']['content']
        
        # Extract JSON from response
        json_str = self.extract_json_from_content(content)
        identification_data = json.loads(json_str)
        
        # Check if composer is Unknown and error if so
        if identification_data.get('composer', '').strip().lower() in ['unknown', '']:
            raise ValueError("Please show clearer composer")
        
        return PieceIdentification(**identification_data)
        
    def extract_json_from_content(self, content: str) -> str:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        content = content.strip()
        
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1]
        
        start = content.find('{')
        if start == -1:
            raise Exception("No JSON object found")
        
        brace_count = 0
        end = start
        
        for i, char in enumerate(content[start:]):
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    end = start + i + 1
                    break
        
        return content[start:end]
    
    def create_simple_search_terms(self, piece_id: PieceIdentification, instrument: str) -> List[Tuple[str, str]]:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        search_terms = []
        
        # Basic search: "title composer instrument"
        basic_search = f"{piece_id.title} {piece_id.composer} {instrument}"
        search_terms.append((basic_search, "basic"))
        
        # Scene-specific search if scene exists: "title composer instrument scene"
        if piece_id.scene_movement:
            scene_search = f"{piece_id.title} {piece_id.composer} {instrument} {piece_id.scene_movement}"
            search_terms.append((scene_search, "scene"))
        
        # Variations without instrument (for ensemble pieces)
        ensemble_search = f"{piece_id.title} {piece_id.composer}"
        search_terms.append((ensemble_search, "ensemble"))
        
        if piece_id.scene_movement:
            ensemble_scene_search = f"{piece_id.title} {piece_id.composer} {piece_id.scene_movement}"
            search_terms.append((ensemble_scene_search, "ensemble_scene"))
        
        print(f"📋 Created {len(search_terms)} search strategies:")
        for i, (term, strategy) in enumerate(search_terms, 1):
            print(f"   {i}. {strategy}: '{term}'")
        
        return search_terms
    
    def search_youtube_simple(self, search_terms: List[Tuple[str, str]]) -> List[VideoResult]:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        all_videos = {}
        
        for term, strategy in search_terms:
            try:
                videos = self.search_youtube_single(term, strategy)
                for video in videos:
                    if video.video_id not in all_videos:
                        all_videos[video.video_id] = video
                
                print(f"  Strategy '{strategy}': {len(videos)} videos")
                
            except Exception as e:
                print(f"  Strategy '{strategy}': Failed - {e}")
        
        print(f"📺 Total unique videos found: {len(all_videos)}")
        return list(all_videos.values())
    
    def get_next_youtube_api_key(self) -> Optional[str]:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        if not YOUTUBE_API_KEYS:
            return None
        
        key = YOUTUBE_API_KEYS[self.current_youtube_key_index]
        self.current_youtube_key_index = (self.current_youtube_key_index + 1) % len(YOUTUBE_API_KEYS)
        return key
    
    def validate_video_id(self, video_id: str) -> bool:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        if not video_id or len(video_id) != 11:
            return False
        # YouTube video IDs are 11 characters long and contain letters, numbers, hyphens, and underscores
        return re.match(r'^[A-Za-z0-9_-]{11}$', video_id) is not None
    
    def search_youtube_single(self, query: str, strategy: str) -> List[VideoResult]:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        search_url = "https://www.googleapis.com/youtube/v3/search"
        
        for attempt in range(len(YOUTUBE_API_KEYS)):
            api_key = self.get_next_youtube_api_key()
            if not api_key:
                raise Exception("No YouTube API keys available")
            
            params = {
                "part": "snippet",
                "q": query,
                "type": "video",
                "maxResults": "10",
                "order": "relevance",
                "key": api_key
            }
            
            try:
                response = requests.get(search_url, params=params, timeout=30)
                
                if response.status_code == 200:
                    data = response.json()
                    items = data.get('items', [])
                    
                    # Validate video IDs before processing
                    valid_video_ids = []
                    for item in items:
                        if 'id' in item and 'videoId' in item['id']:
                            video_id = item['id']['videoId']
                            if self.validate_video_id(video_id):
                                valid_video_ids.append(video_id)
                            else:
                                print(f"    ⚠️ Invalid video ID format: {video_id}")
                    
                    if valid_video_ids:
                        return self.get_video_details(valid_video_ids, strategy, api_key)
                    else:
                        print(f"    ⚠️ No valid video IDs found for query: {query}")
                        return []
                
                elif response.status_code in [403, 429]:
                    print(f"    YouTube API key issue (status {response.status_code}), trying next key...")
                    continue
                else:
                    print(f"    YouTube API returned status {response.status_code}")
                    continue
            
            except requests.exceptions.RequestException as e:
                print(f"    Request error: {e}")
                if attempt == len(YOUTUBE_API_KEYS) - 1:
                    raise Exception(f"All YouTube API keys failed: {str(e)}")
                continue
        
        return []
    
    def get_video_details(self, video_ids: List[str], strategy: str, api_key: str) -> List[VideoResult]:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        details_url = "https://www.googleapis.com/youtube/v3/videos"
        
        # Process video IDs in smaller batches to avoid 400 errors
        batch_size = 5
        all_videos = []
        
        for i in range(0, len(video_ids), batch_size):
            batch_ids = video_ids[i:i + batch_size]
            
            params = {
                "part": "contentDetails,snippet,statistics",
                "id": ",".join(batch_ids),
                "key": api_key
            }
            
            try:
                print(f"    📡 Fetching details for {len(batch_ids)} videos...")
                response = requests.get(details_url, params=params, timeout=30)
                
                if response.status_code == 200:
                    data = response.json()
                    items = data.get('items', [])
                    
                    for item in items:
                        try:
                            video = self.parse_video_item(item, strategy)
                            if video:
                                all_videos.append(video)
                        except Exception as e:
                            print(f"    ⚠️ Error parsing video item: {e}")
                            continue
                            
                elif response.status_code == 400:
                    print(f"    ⚠️ Bad request for batch {i//batch_size + 1}, trying individual requests...")
                    # Try each video ID individually
                    for video_id in batch_ids:
                        try:
                            individual_videos = self.get_single_video_details(video_id, strategy, api_key)
                            all_videos.extend(individual_videos)
                        except Exception as e:
                            print(f"    ⚠️ Failed to get details for video {video_id}: {e}")
                            continue
                else:
                    print(f"    ⚠️ Video details API returned status {response.status_code}")
                    continue
                    
            except requests.exceptions.RequestException as e:
                print(f"    ⚠️ Request error getting video details: {e}")
                continue
        
        return all_videos
    
    def get_single_video_details(self, video_id: str, strategy: str, api_key: str) -> List[VideoResult]:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        details_url = "https://www.googleapis.com/youtube/v3/videos"
        
        params = {
            "part": "contentDetails,snippet,statistics",
            "id": video_id,
            "key": api_key
        }
        
        try:
            response = requests.get(details_url, params=params, timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                items = data.get('items', [])
                
                if items:
                    video = self.parse_video_item(items[0], strategy)
                    return [video] if video else []
                else:
                    print(f"    ⚠️ No data returned for video {video_id}")
                    return []
            else:
                print(f"    ⚠️ Failed to get details for video {video_id}: status {response.status_code}")
                return []
                
        except Exception as e:
            print(f"    ⚠️ Error getting single video details: {e}")
            return []
    
    def parse_video_item(self, item: dict, strategy: str) -> Optional[VideoResult]:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        try:
            video_id = item['id']
            snippet = item['snippet']
            statistics = item['statistics']
            content_details = item['contentDetails']
            
            title = snippet['title']
            channel = snippet['channelTitle']
            duration_iso = content_details['duration']
            
            views = int(statistics.get('viewCount', 0))
            likes = int(statistics.get('likeCount', 0))
            
            duration_seconds = self.parse_youtube_duration(duration_iso)
            duration_text = self.format_duration(duration_seconds)
            
            video_url = f"https://www.youtube.com/watch?v={video_id}"
            
            return VideoResult(
                video_id=video_id,
                title=title,
                channel=channel,
                video_url=video_url,
                views=views,
                likes=likes,
                duration=duration_text,
                duration_seconds=duration_seconds,
                search_strategy=strategy,
                title_match_score=0.0,  # Will be calculated later
                composer_match_score=0.0,  # Will be calculated later
                scene_match_score=0.0,  # Will be calculated later
                duration_match_score=0.0,  # Will be calculated later
                overall_accuracy_score=0.0  # Will be calculated later
            )
            
        except (KeyError, ValueError) as e:
            print(f"    ⚠️ Error parsing video data: {e}")
            return None
    
    def parse_youtube_duration(self, duration_iso: str) -> int:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        try:
            duration = isodate.parse_duration(duration_iso)
            return int(duration.total_seconds())
        except Exception:
            return 0
    
    def format_duration(self, seconds: int) -> str:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        minutes = seconds // 60
        remaining_seconds = seconds % 60
        
        if minutes >= 60:
            hours = minutes // 60
            remaining_minutes = minutes % 60
            return f"{hours}:{remaining_minutes:02d}:{remaining_seconds:02d}"
        else:
            return f"{minutes}:{remaining_seconds:02d}"
    
    def rank_by_accuracy(self, videos: List[VideoResult], piece_id: PieceIdentification, instrument: str) -> List[VideoResult]:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        if not videos:
            return []
        
        try:
            url = "https://api.groq.com/openai/v1/chat/completions"
            
            # Prepare video data for scoring
            videos_data = []
            for video in videos:
                videos_data.append({
                    "id": video.video_id,
                    "title": video.title,
                    "channel": video.channel,
                    "views": video.views,
                    "duration": video.duration,
                    "search_strategy": video.search_strategy
                })
            
            prompt = f"""Score these YouTube videos for accuracy in matching this musical piece:

TARGET PIECE:
- Title: "{piece_id.title}"
- Composer: "{piece_id.composer}"
- Scene/Movement: "{piece_id.scene_movement or 'N/A'}"
- Target Instrument: "{instrument}"

VIDEOS TO SCORE:
{json.dumps(videos_data, indent=2)}

For each video, provide scores (0-10 scale):

1. **title_match_score**: How well does the video title match "{piece_id.title}"?
   - 10: Exact match
   - 8-9: Very close match with minor variations
   - 6-7: Recognizable match but with differences
   - 4-5: Partial match
   - 0-3: Poor or no match

2. **composer_match_score**: How well does the video mention "{piece_id.composer}"?
   - 10: Exact composer name match
   - 8-9: Very close (e.g., "Tchaikovsky" vs "P.I. Tchaikovsky")
   - 6-7: Recognizable but abbreviated
   - 4-5: Partial mention
   - 0-3: Wrong or missing composer

3. **scene_match_score**: {"If scene/movement is: " + piece_id.scene_movement if piece_id.scene_movement else "Since no specific scene/movement was identified"}
   {"- 10: Exact scene/movement match" if piece_id.scene_movement else "- 5: Default score (no scene to match)"}
   {"- 8-9: Very close scene match" if piece_id.scene_movement else ""}
   {"- 6-7: Related scene/movement" if piece_id.scene_movement else ""}
   {"- 4-5: Different scene from same work" if piece_id.scene_movement else ""}
   {"- 0-3: Wrong or unrelated" if piece_id.scene_movement else ""}

4. **duration_match_score**: How appropriate is the video duration for this piece?
   Consider these factors:
   - Is this likely a complete performance or just an excerpt?
   - Does the duration make sense for the identified piece/movement?
   - Very short videos (< 2 minutes) are likely excerpts or practice sessions
   - Very long videos (> 45 minutes) might be full concerts with multiple pieces
   - For solo pieces: 3-15 minutes often indicates complete movements
   - For orchestral movements: 5-20 minutes often indicates complete movements
   - For opera scenes: 3-12 minutes often indicates complete scenes
   
   Scoring:
   - 10: Perfect duration for a complete performance of this piece/movement
   - 8-9: Good duration, likely complete or nearly complete
   - 6-7: Reasonable duration but might be abbreviated
   - 4-5: Duration suggests partial performance or excerpt
   - 0-3: Duration clearly wrong (too short/long for this piece)

5. **overall_accuracy_score**: Weighted average
   - title_match_score * 0.35
   - composer_match_score * 0.35  
   - scene_match_score * 0.15
   - duration_match_score * 0.15

CRITICAL REQUIREMENTS:
- Videos with WRONG piece titles should get title_match_score ≤ 3
- Videos with WRONG composers should get composer_match_score ≤ 3
- Videos that are clearly excerpts (< 90 seconds) should get duration_match_score ≤ 4
- Only give high scores (8+) to videos that are clearly the correct piece with appropriate duration

Return ONLY a JSON array with this format:
[
  {{
    "video_id": "id1",
    "title_match_score": 8.5,
    "composer_match_score": 9.0,
    "scene_match_score": 7.0,
    "duration_match_score": 8.0,
    "overall_accuracy_score": 8.1
  }},
  ...
]"""
            
            payload = {
                "model": "llama-3.3-70b-versatile",
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 1000,
                "temperature": 0.1
            }
            
            headers = {
                'Authorization': f'Bearer {GROQ_API_KEY}',
                'Content-Type': 'application/json'
            }
            
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            content = data['choices'][0]['message']['content']
            
            # Extract JSON array from response
            scores_data = json.loads(self.extract_json_array_from_content(content))
            
            # Apply scores to videos
            video_dict = {video.video_id: video for video in videos}
            
            for score_item in scores_data:
                video_id = score_item['video_id']
                if video_id in video_dict:
                    video = video_dict[video_id]
                    video.title_match_score = score_item['title_match_score']
                    video.composer_match_score = score_item['composer_match_score']
                    video.scene_match_score = score_item['scene_match_score']
                    video.duration_match_score = score_item['duration_match_score']
                    video.overall_accuracy_score = score_item['overall_accuracy_score']
            
            # Sort by overall accuracy score (prioritizing scene matches)
            ranked_videos = sorted(videos, key=lambda x: (x.overall_accuracy_score, x.scene_match_score), reverse=True)
            
            print(f"🎯 Ranked {len(ranked_videos)} videos by accuracy")
            print("🏆 Top 3 most accurate matches:")
            for i, video in enumerate(ranked_videos[:3]):
                print(f"  {i+1}. Score: {video.overall_accuracy_score:.1f}/10")
                print(f"     Title: {video.title[:50]}...")
                print(f"     Scores - Title: {video.title_match_score:.1f}, Composer: {video.composer_match_score:.1f}, Scene: {video.scene_match_score:.1f}")
            
            return ranked_videos
            
        except Exception as e:
            print(f"⚠️ Accuracy ranking failed: {e}, using fallback")
            # Fallback: simple ranking by views
            return sorted(videos, key=lambda x: x.views, reverse=True)
    
    def extract_json_array_from_content(self, content: str) -> str:
        """EXACT SAME METHOD AS STANDALONE VERSION"""
        content = content.strip()
        
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1]
        
        start = content.find('[')
        end = content.rfind(']')
        
        if start != -1 and end != -1 and end > start:
            return content[start:end + 1]
        
        raise Exception("No JSON array found in content")

# Flask App Setup
app = Flask(__name__)
CORS(app)

# Initialize scanner with EXACT SAME LOGIC
scanner = AccurateMusicScannerAPI()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "Music Scanner API with EXACT Standalone Logic"})

@app.route('/instruments', methods=['GET'])
def get_supported_instruments():
    """Get list of supported instruments"""
    return jsonify({
        "supported_instruments": SUPPORTED_INSTRUMENTS,
        "default": "clarinet",
        "total_count": len(SUPPORTED_INSTRUMENTS)
    })

@app.route('/scan', methods=['POST'])
def scan_music():
    """
    Scan sheet music using EXACT SAME LOGIC as working standalone version
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
        
        # Get image data
        image_data_b64 = data.get('image')
        if not image_data_b64:
            return jsonify({"error": "No image data provided"}), 400
        
        # Get instrument - required
        target_instrument = data.get('instrument')
        if not target_instrument:
            return jsonify({
                "error": "Instrument parameter is required",
                "supported_instruments": SUPPORTED_INSTRUMENTS[:10],
                "example": "clarinet"
            }), 400
        
        # Validate image data format
        try:
            base64.b64decode(image_data_b64)
        except Exception:
            return jsonify({"error": "Invalid base64 image data"}), 400
        
        print(f"🎵 Processing scan request for instrument: {target_instrument}")
        
        # Use EXACT SAME LOGIC as standalone version
        result = scanner.scan_music_from_base64(image_data_b64, target_instrument)
        
        # Check if we got a valid result or an error
        if result["piece_identification"]["confidence"] == "low":
            # This is an error response
            return jsonify(result), 422  # Unprocessable Entity
        
        # Return successful analysis and video data
        return jsonify(result)
    
    except Exception as e:
        print(f"❌ API Error: {str(e)}")
        error_response = scanner.create_error_response(f"API error: {str(e)}")
        return jsonify(error_response), 500

@app.route('/')
def home():
    """Web interface for testing"""
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Music Scanner API - EXACT Standalone Logic</title>
        <style>
            body {{ font-family: Arial, sans-serif; max-width: 1000px; margin: 0 auto; padding: 20px; }}
            .container {{ background: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0; }}
            select, input, button {{ padding: 10px; margin: 10px 0; border-radius: 5px; border: 1px solid #ddd; }}
            button {{ background: #007bff; color: white; cursor: pointer; padding: 15px 30px; }}
            button:hover {{ background: #0056b3; }}
            #result {{ background: white; padding: 20px; border-radius: 5px; margin-top: 20px; }}
            .loading {{ color: #007bff; font-weight: bold; }}
            .error {{ color: red; font-weight: bold; background: #ffe6e6; padding: 15px; border-radius: 5px; }}
            .success {{ color: green; font-weight: bold; }}
            .warning {{ color: orange; background: #fff3cd; padding: 15px; border-radius: 5px; }}
            .piece-info {{ background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 15px 0; }}
            .video-item {{ border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 8px; background: #fafafa; }}
            .video-rank {{ display: inline-block; background: #007bff; color: white; padding: 5px 10px; border-radius: 50%; font-weight: bold; margin-right: 10px; }}
            .video-title {{ font-weight: bold; color: #333; margin: 5px 0; }}
            .video-channel {{ color: #666; margin: 5px 0; }}
            .video-stats {{ color: #888; font-size: 0.9em; margin: 5px 0; }}
            .video-url {{ margin-top: 10px; }}
            .video-url a {{ color: #007bff; text-decoration: none; }}
            .video-url a:hover {{ text-decoration: underline; }}
            .accuracy-scores {{ background: #f8f9fa; padding: 10px; border-radius: 5px; margin: 5px 0; font-size: 0.9em; }}
            .accuracy-high {{ color: #28a745; }}
            .accuracy-medium {{ color: #ffc107; }}
            .accuracy-low {{ color: #dc3545; }}
        </style>
    </head>
    <body>
        <h1>🎵 Music Scanner API - EXACT Standalone Logic</h1>
        <p><strong>✅ Using EXACT same logic as working standalone version!</strong></p>
        
        <div class="container">
            <h2>Test the API</h2>
            
            <label for="instrument">Choose Instrument:</label><br>
            <select id="instrument" style="width: 200px;">
                {''.join([f'<option value="{inst}">{inst.title()}</option>' for inst in SUPPORTED_INSTRUMENTS])}
            </select><br><br>
            
            <label for="imageFile">Upload Sheet Music Image:</label><br>
            <input type="file" id="imageFile" accept="image/*" style="width: 300px;"><br><br>
            
            <button onclick="scanImage()">🔍 Scan Sheet Music</button>
            <button onclick="testAPI()">🧪 Test API</button>
        </div>
        
        <div id="result"></div>
        
        <script>
            async function scanImage() {{
                const instrument = document.getElementById('instrument').value;
                const fileInput = document.getElementById('imageFile');
                const resultDiv = document.getElementById('result');
                
                if (!fileInput.files[0]) {{
                    resultDiv.innerHTML = '<div class="error">❌ Please select an image file</div>';
                    return;
                }}
                
                resultDiv.innerHTML = '<div class="loading">📸 Processing image...</div>';
                
                try {{
                    const file = fileInput.files[0];
                    const base64 = await fileToBase64(file);
                    
                    resultDiv.innerHTML = '<div class="loading">🤖 Analyzing sheet music...</div>';
                    
                    const response = await fetch('/scan', {{
                        method: 'POST',
                        headers: {{'Content-Type': 'application/json'}},
                        body: JSON.stringify({{
                            image: base64,
                            instrument: instrument
                        }})
                    }});
                    
                    const data = await response.json();
                    
                    if (response.status === 422) {{
                        displayFailedResult(data, instrument);
                    }} else if (response.ok) {{
                        displayResult(data, instrument);
                    }} else {{
                        throw new Error(`HTTP ${{response.status}}: ${{data.error || 'Unknown error'}}`);
                    }}
                    
                }} catch (error) {{
                    resultDiv.innerHTML = `<div class="error">❌ Error: ${{error.message}}</div>`;
                }}
            }}
            
            async function testAPI() {{
                const instrument = document.getElementById('instrument').value;
                const resultDiv = document.getElementById('result');
                
                resultDiv.innerHTML = '<div class="loading">🧪 Testing API...</div>';
                
                try {{
                    const response = await fetch('/scan', {{
                        method: 'POST',
                        headers: {{'Content-Type': 'application/json'}},
                        body: JSON.stringify({{
                            image: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==",
                            instrument: instrument
                        }})
                    }});
                    
                    const result = await response.json();
                    
                    if (response.status === 422) {{
                        displayFailedResult(result, instrument, "Test Result (Fast Fail) - ");
                    }} else {{
                        displayResult(result, instrument, "Test Result - ");
                    }}
                }} catch (error) {{
                    resultDiv.innerHTML = `<div class="error">❌ Error: ${{error.message}}</div>`;
                }}
            }}
            
            function displayFailedResult(data, instrument, prefix = "") {{
                const resultDiv = document.getElementById('result');
                const reason = data.piece_identification?.reasoning || 'Unknown reason';
                
                resultDiv.innerHTML = `
                    <div class="warning">⚠️ ${{prefix}}Fast-fail for ${{instrument}}: ${{reason}}</div>
                    <div class="piece-info">
                        <h3>🔍 Analysis Details</h3>
                        <p><strong>Confidence:</strong> ${{data.piece_identification?.confidence || 'low'}}</p>
                        <p><strong>Reasoning:</strong> ${{reason}}</p>
                        <p><strong>Suggestion:</strong> Try uploading a clearer image of sheet music with visible title and composer information.</p>
                    </div>
                `;
            }}
            
            function fileToBase64(file) {{
                return new Promise((resolve, reject) => {{
                    const reader = new FileReader();
                    reader.readAsDataURL(file);
                    reader.onload = () => {{
                        const base64 = reader.result.split(',')[1];
                        resolve(base64);
                    }};
                    reader.onerror = error => reject(error);
                }});
            }}
            
            function getAccuracyClass(score) {{
                if (score >= 8.0) return 'accuracy-high';
                if (score >= 6.0) return 'accuracy-medium';
                return 'accuracy-low';
            }}
            
            function getAccuracyIcon(score) {{
                if (score >= 8.0) return '🎯';
                if (score >= 6.0) return '✅';
                return '📹';
            }}
            
            function displayResult(data, instrument, prefix = "") {{
                const resultDiv = document.getElementById('result');
                
                if (data.videos && data.videos.length > 0) {{
                    const highAccuracyCount = data.videos.filter(v => v.overall_accuracy_score >= 6.0).length;
                    const sceneMatches = data.videos.filter(v => v.scene_match_score >= 8.0).length;
                    
                    let html = `
                        <div class="success">✅ ${{prefix}}Found ${{data.videos.length}} YouTube videos for ${{instrument}}! (${{highAccuracyCount}} high accuracy, ${{sceneMatches}} with scene matches)</div>
                        
                        <div class="piece-info">
                            <h3>🎼 Piece Identification</h3>
                            <p><strong>Title:</strong> ${{data.piece_identification?.title || 'Unknown'}}</p>
                            <p><strong>Composer:</strong> ${{data.piece_identification?.composer || 'Unknown'}}</p>
                            <p><strong>Scene/Movement:</strong> ${{data.piece_identification?.scene_movement || 'N/A'}}</p>
                            <p><strong>Confidence:</strong> ${{data.piece_identification?.confidence || 'Unknown'}}</p>
                            <p><strong>Reasoning:</strong> ${{data.piece_identification?.reasoning || 'Unknown'}}</p>
                        </div>
                        
                        <h3>🎵 Ranked Videos (Best to Worst)</h3>
                    `;
                    
                    data.videos.forEach((video, index) => {{
                        const accuracyIcon = getAccuracyIcon(video.overall_accuracy_score || 0);
                        const sceneIcon = (video.scene_match_score >= 8.0) ? '🎭' : '';
                        
                        html += `
                            <div class="video-item">
                                <span class="video-rank">${{index + 1}}</span>
                                ${{accuracyIcon}}${{sceneIcon}}
                                <div class="video-title">${{video.title}}</div>
                                <div class="video-channel">📺 ${{video.channel}}</div>
                                <div class="video-stats">
                                    ⏱️ ${{video.duration}} | 
                                    👀 ${{video.views?.toLocaleString() || 0}} views | 
                                    👍 ${{video.likes?.toLocaleString() || 0}} likes |
                                    🎯 Strategy ${{video.search_strategy}}
                                </div>
                        `;
                        
                        if (video.overall_accuracy_score !== undefined) {{
                            html += `
                                <div class="accuracy-scores">
                                    <strong>🎯 Accuracy Scores:</strong><br>
                                    Overall: <span class="${{getAccuracyClass(video.overall_accuracy_score)}}">${{video.overall_accuracy_score?.toFixed(1) || 'N/A'}}/10</span> |
                                    Title: <span class="${{getAccuracyClass(video.title_match_score || 0)}}">${{video.title_match_score?.toFixed(1) || 'N/A'}}/10</span> |
                                    Composer: <span class="${{getAccuracyClass(video.composer_match_score || 0)}}">${{video.composer_match_score?.toFixed(1) || 'N/A'}}/10</span> |
                                    Scene: <span class="${{getAccuracyClass(video.scene_match_score || 0)}}">${{video.scene_match_score?.toFixed(1) || 'N/A'}}/10</span> |
                                    Duration: <span class="${{getAccuracyClass(video.duration_match_score || 0)}}">${{video.duration_match_score?.toFixed(1) || 'N/A'}}/10</span>
                                </div>
                            `;
                        }}
                        
                        html += `
                                <div class="video-url">
                                    <a href="${{video.url}}" target="_blank">🔗 Open on YouTube</a>
                                </div>
                            </div>
                        `;
                    }});
                    
                    resultDiv.innerHTML = html;
                }} else {{
                    resultDiv.innerHTML = `
                        <div class="error">❌ No videos found for ${{instrument}}</div>
                        <div class="piece-info">
                            <h3>🎼 Piece Identification (if any)</h3>
                            <p><strong>Title:</strong> ${{data.piece_identification?.title || 'Unknown'}}</p>
                            <p><strong>Composer:</strong> ${{data.piece_identification?.composer || 'Unknown'}}</p>
                            <p><strong>Confidence:</strong> ${{data.piece_identification?.confidence || 'Unknown'}}</p>
                            <p><strong>Reasoning:</strong> ${{data.piece_identification?.reasoning || 'Unknown'}}</p>
                        </div>
                    `;
                }}
            }}
        </script>
    </body>
    </html>
    """
    return html

def main():
    """Main function to run the Flask app with EXACT standalone logic"""
    print("🎵 Starting Music Scanner API with EXACT Standalone Logic...")
    print("🎯 Using simplified accuracy-focused approach")
    print("🔧 Fixed YouTube API handling and error recovery")
    print("Available endpoints:")
    print("  GET  /health      - Health check")
    print("  GET  /instruments - List supported instruments") 
    print("  POST /scan        - Complete scan with piece identification + video data")
    print(f"  Supported instruments: {len(SUPPORTED_INSTRUMENTS)} total")
    print("✅ EXACT SAME LOGIC as working standalone version!")
    app.run(debug=True, host='0.0.0.0', port=8000)

if __name__ == '__main__':
    main()
