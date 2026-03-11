#!/usr/bin/env python3
"""
创建武器预制体：木剑和木弓
基于现有Arrow.prefab修改
"""

import os
import sys
import random

def read_prefab(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write_prefab(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def create_sword_prefab():
    # 基于Arrow.prefab创建木剑预制体
    arrow_path = "/app/data/files/temp/Assets/Assets/┼╔╧╡/Arrow.prefab"
    content = read_prefab(arrow_path)
    
    lines = content.splitlines()
    new_lines = []
    
    # 生成唯一的fileID
    import random
    existing_ids = set()
    for line in lines:
        if line.startswith('--- !u!') and '&' in line:
            parts = line.split('&')
            if len(parts) > 1:
                file_id = parts[1].strip()
                existing_ids.add(file_id)
    
    # 为组件生成新的fileID
    def generate_unique_id():
        while True:
            new_id = random.randint(1000000000000000000, 9999999999999999999)
            if str(new_id) not in existing_ids:
                existing_ids.add(str(new_id))
                return str(new_id)
    
    # 我们需要修改以下部分：
    # 1. GameObject的m_Name和组件列表
    # 2. 替换ArrowProjectile组件为Weapon组件
    # 3. 可能修改SpriteRenderer的sprite引用
    
    # 首先，找到各个组件的section
    sections = []
    current_section = []
    for line in lines:
        if line.startswith('--- !u!'):
            if current_section:
                sections.append(current_section)
            current_section = [line]
        else:
            if current_section:
                current_section.append(line)
    if current_section:
        sections.append(current_section)
    
    # 识别各个部分
    game_object_section = None
    transform_section = None
    sprite_renderer_section = None
    collider_section = None
    arrow_projectile_section = None
    rigidbody_section = None
    
    for section in sections:
        first_line = section[0]
        if first_line.startswith('--- !u!1'):
            game_object_section = section
        elif first_line.startswith('--- !u!4'):
            transform_section = section
        elif first_line.startswith('--- !u!212'):
            sprite_renderer_section = section
        elif first_line.startswith('--- !u!61'):
            collider_section = section
        elif first_line.startswith('--- !u!114'):
            # 可能是ArrowProjectile
            for line in section:
                if 'ArrowProjectile' in line:
                    arrow_projectile_section = section
                    break
        elif first_line.startswith('--- !u!50'):
            rigidbody_section = section
    
    # 修改GameObject部分
    if game_object_section:
        for i, line in enumerate(game_object_section):
            if 'm_Name: Arrow' in line:
                game_object_section[i] = line.replace('Arrow', 'Sword_Wood')
    
    # 修改SpriteRenderer部分 - 更换精灵引用
    # 我们需要知道Square.png的fileID，但这里先保持原样
    # 实际上，精灵引用会在编辑器中设置
    
    # 替换ArrowProjectile部分为Weapon组件
    if arrow_projectile_section:
        # 替换第一行的fileID（保持不变）
        # 替换内容
        new_section = []
        new_section.append(arrow_projectile_section[0])  # --- !u!114 &xxx
        new_section.append('MonoBehaviour:')
        new_section.append('  m_ObjectHideFlags: 0')
        new_section.append('  m_CorrespondingSourceObject: {fileID: 0}')
        new_section.append('  m_PrefabInstance: {fileID: 0}')
        new_section.append('  m_PrefabAsset: {fileID: 0}')
        new_section.append('  m_GameObject: {fileID: ' + game_object_section[0].split('&')[1].strip() + '}')
        new_section.append('  m_Enabled: 1')
        new_section.append('  m_EditorHideFlags: 0')
        new_section.append('  m_Script: {fileID: 11500000, guid: 生成唯一GUID, type: 3}')
        new_section.append('  m_Name: ')
        new_section.append('  m_EditorClassIdentifier: ')
        new_section.append('  data:')
        new_section.append('    weaponId: sword_wood')
        new_section.append('    displayName: 木剑')
        new_section.append('    weaponType: 0')  # Melee
        new_section.append('    damage: 5')
        new_section.append('    attackSpeed: 1.2')
        new_section.append('    range: 1.0')
        new_section.append('    effects: []')
        # 注意：这里简化处理，实际的MonoBehaviour序列化更复杂
    
        # 找到arrow_projectile_section在sections中的索引并替换
        for idx, section in enumerate(sections):
            if section == arrow_projectile_section:
                sections[idx] = new_section
                break
    
    # 重新组合所有行
    new_lines = []
    for section in sections:
        new_lines.extend(section)
    
    output_path = "/app/data/files/漂浮大陆/Assets/Prefabs/Weapons/Sword_Wood.prefab"
    write_prefab(output_path, '\n'.join(new_lines))
    print(f"创建木剑预制体: {output_path}")

def create_bow_prefab():
    # 创建木弓预制体，类似木剑但不同参数
    arrow_path = "/app/data/files/temp/Assets/Assets/┼╔╧╡/Arrow.prefab"
    content = read_prefab(arrow_path)
    
    lines = content.splitlines()
    
    # 简单替换名称和部分参数
    new_content = content.replace('Arrow', 'Bow_Wood')
    # 更多参数可以在编辑器中设置
    
    output_path = "/app/data/files/漂浮大陆/Assets/Prefabs/Weapons/Bow_Wood.prefab"
    write_prefab(output_path, new_content)
    print(f"创建木弓预制体: {output_path}")

def main():
    print("开始创建武器预制体...")
    create_sword_prefab()
    create_bow_prefab()
    print("武器预制体创建完成")

if __name__ == "__main__":
    main()