# Kalye-Corazon
GameOn

## Technical Architecture  

Our game Kalye Corazon is developed using the Godot Engine, structured around its node and scene system to ensure modularity and scalability.  

### Scene Structure  
Level1_QuestonHall  
- Background and visual elements – Environment and aesthetics  
- Player Character – Built with `CharacterBody2D`, including:  
  - `CollisionShape2D` – Handles collisions  
  - `Sprite2D` – Manages animations  
  - `Camera2D` – Tracks player movement  
- Boundaries – Implemented with static nodes to keep the player inside the playable space  
- Transition Zones – Collision nodes that detect state changes  
- NPC Guide (Cat) – An interactive component that drives progression  

### Gameplay Flow  
- Player progression is controlled by collision triggers.  
- When the player collides with a designated `CollisionShape2D`, the Word Assembly Mini-Game is dynamically loaded using scene instancing.  
- While the mini-game is active:  
  - Player input is temporarily disabled to prevent conflicts.  
  - The mini-game exists only in memory for efficiency.   

### Key Benefits  
- Clean separation of concerns between player mechanics, puzzles, and NPCs  
- Memory-efficient with on-demand scene instancing  
- Easily expandable for adding new mini-games, challenges, or NPCs without redesigning core systems  


## Summary  
Kalye Corazón is a narrative-driven simulation game developed in Godot, inspired by Ilonggo culture. Exploring themes of community, civic engagement, health, wellbeing, and environment, it follows Caleb, a CICT student battling academic burnout, whose healing is guided by the WVSU cats—Mango and Eveready. By leveraging Godot’s node hierarchy, scene instancing, and signal system, the game achieves a scalable, maintainable, and efficient architecture that ensures smooth gameplay while allowing room for future growth. 
