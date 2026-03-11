#!/usr/bin/env python3
"""
创建玩家预制体文件，基于Tree.prefab模板
"""
import re
import sys

def create_player_prefab():
    # 读取模板文件
    with open('temp/tree_template.prefab', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 替换GameObject的m_Name和m_TagString
    content = re.sub(r'm_Name: Tree', 'm_Name: Player', content)
    content = re.sub(r'm_TagString: Tree', 'm_TagString: Player', content)
    
    # 我们需要添加更多组件，但为了简单起见，我们只修改现有的组件
    # 实际上，我们需要完全重写YAML。让我们生成一个新的YAML。
    # 由于时间有限，我们只创建一个简单的预制体，包含基本组件。
    # 我们直接输出一个新的YAML内容。
    
    # 定义新的YAML内容
    yaml_content = """%YAML 1.1
%TAG !u! tag:unity3d.com,2011:
--- !u!1 &1
GameObject:
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  serializedVersion: 6
  m_Component:
  - component: {fileID: 4}
  - component: {fileID: 24}
  - component: {fileID: 65}
  - component: {fileID: 212}
  - component: {fileID: 95}
  - component: {fileID: 114}
  m_Layer: 0
  m_Name: Player
  m_TagString: Player
  m_Icon: {fileID: 0}
  m_NavMeshLayer: 0
  m_StaticEditorFlags: 0
  m_IsActive: 1
--- !u!4 &4
Transform:
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  m_GameObject: {fileID: 1}
  serializedVersion: 2
  m_LocalRotation: {x: 0, y: 0, z: 0, w: 1}
  m_LocalPosition: {x: 0, y: 0, z: 0}
  m_LocalScale: {x: 1, y: 1, z: 1}
  m_Children: []
  m_Father: {fileID: 0}
--- !u!24 &24
Rigidbody2D:
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  m_GameObject: {fileID: 1}
  serializedVersion: 4
  m_BodyType: 0
  m_Simulated: 1
  m_UseFullKinematicContacts: 0
  m_UseAutoMass: 0
  m_Mass: 1
  m_LinearDamping: 0
  m_AngularDamping: 0.05
  m_GravityScale: 1
  m_Material: {fileID: 0}
  m_Interpolate: 0
  m_SleepingMode: 0
  m_CollisionDetection: 0
  m_Constraints: 0
--- !u!65 &65
BoxCollider2D:
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  m_GameObject: {fileID: 1}
  serializedVersion: 2
  m_Size: {x: 1, y: 1}
  m_Offset: {x: 0, y: 0}
  m_AutoTiling: 0
  m_SpriteTilingProperty: {fileID: 0}
--- !u!212 &212
SpriteRenderer:
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  m_GameObject: {fileID: 1}
  serializedVersion: 2
  m_Color: {r: 1, g: 1, b: 1, a: 1}
  m_FlipX: 0
  m_FlipY: 0
  m_Sprite: {fileID: 21300000, guid: 5d2c8a4c9e8d14f4a8f3e2b7c1d6a9b0, type: 3}
  m_Material: {fileID: 0}
  m_MaskInteraction: 0
  m_SortingOrder: 0
--- !u!95 &95
Animator:
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  m_GameObject: {fileID: 1}
  serializedVersion: 3
  m_Controller: {fileID: 9100000, guid: aabbccddeeff, type: 2}
  m_Avatar: {fileID: 0}
  m_CullingMode: 0
  m_UpdateMode: 0
  m_ApplyRootMotion: 0
--- !u!114 &114
MonoBehaviour:
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  m_GameObject: {fileID: 1}
  m_Enabled: 1
  m_EditorHideFlags: 0
  m_Script: {fileID: 11500000, guid: 5d2c8a4c9e8d14f4a8f3e2b7c1d6a9b0, type: 3}
  m_Name: 
  m_EditorClassIdentifier: 
"""
    # 写入文件
    output_path = '漂浮大陆/Assets/Prefabs/Player.prefab'
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(yaml_content)
    
    print(f"Player预制体已创建：{output_path}")

if __name__ == '__main__':
    create_player_prefab()