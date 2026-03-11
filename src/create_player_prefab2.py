#!/usr/bin/env python3
"""
基于Wood.prefab创建Player预制体，添加Animator、playerMovement和CameraFollow组件
"""

import os
import sys

def read_wood_prefab():
    wood_path = "/app/data/files/漂浮大陆/Assets/Wood.prefab"
    with open(wood_path, 'r', encoding='utf-8') as f:
        return f.read()

def create_player_prefab():
    content = read_wood_prefab()
    
    # 分割成行
    lines = content.splitlines()
    
    # 找出组件部分
    component_sections = []
    current_section = []
    in_section = False
    
    for i, line in enumerate(lines):
        if line.startswith('--- !u!'):
            if current_section:
                component_sections.append(current_section)
            current_section = [line]
            in_section = True
        elif in_section:
            current_section.append(line)
    
    if current_section:
        component_sections.append(current_section)
    
    # 第一个部分是GameObject，接着是Transform等
    # 我们需要修改GameObject的名称和组件列表
    new_lines = []
    
    # 生成新的fileID，确保唯一性
    # 我们将保留原有的fileID，但添加新组件
    # 首先，收集现有的fileID
    existing_file_ids = set()
    for section in component_sections:
        first_line = section[0]
        # 格式: --- !u!4 &3480471270219422480
        if '&' in first_line:
            file_id = first_line.split('&')[1].strip()
            existing_file_ids.add(file_id)
    
    # 生成新组件的fileID
    import random
    new_file_ids = set()
    while len(new_file_ids) < 3:
        new_id = random.randint(1000000000000000000, 9999999999999999999)
        if str(new_id) not in existing_file_ids:
            new_file_ids.add(str(new_id))
    
    new_file_ids = list(new_file_ids)
    animator_file_id = new_file_ids[0]
    player_movement_file_id = new_file_ids[1]
    camera_follow_file_id = new_file_ids[2]
    
    # 修改GameObject部分
    for i, section in enumerate(component_sections):
        if section[0].startswith('--- !u!1'):
            # GameObject部分
            for j, line in enumerate(section):
                if 'm_Name: Wood' in line:
                    section[j] = line.replace('Wood', 'Player')
                elif 'm_TagString: Untagged' in line:
                    section[j] = line.replace('Untagged', 'Player')
                elif 'm_Component:' in line:
                    # 找到组件列表，需要添加新组件的引用
                    # 组件列表格式:
                    #   m_Component:
                    #   - component: {fileID: x}
                    #   - component: {fileID: y}
                    # 我们将在列表末尾添加新引用
                    k = j + 1
                    while k < len(section) and section[k].startswith('  - component:'):
                        k += 1
                    # 现在k指向组件列表结束的位置
                    # 插入新组件的引用
                    new_refs = [
                        f'  - component: {{fileID: {animator_file_id}}}',
                        f'  - component: {{fileID: {player_movement_file_id}}}',
                        f'  - component: {{fileID: {camera_follow_file_id}}}'
                    ]
                    for ref in reversed(new_refs):
                        section.insert(k, ref)
                    break
    
    # 构建Animator组件部分
    animator_section = [
        f'--- !u!95 &{animator_file_id}',
        'Animator:',
        '  m_ObjectHideFlags: 0',
        '  m_CorrespondingSourceObject: {fileID: 0}',
        '  m_PrefabInstance: {fileID: 0}',
        '  m_PrefabAsset: {fileID: 0}',
        '  m_GameObject: {fileID: 99808851631468291}',
        '  m_Enabled: 1',
        '  m_Avatar: {fileID: 0}',
        '  m_Controller: {fileID: 9100000, guid: f63b86da30f8dba4a8455b3f467067e7, type: 2}',
        '  m_CullingMode: 0',
        '  m_UpdateMode: 0',
        '  m_ApplyRootMotion: 0',
        '  m_LinearVelocityBlending: 0',
        '  m_WarningMessage: ',
        '  m_HasTransformHierarchy: 1',
        '  m_AllowConstantClipSamplingOptimization: 1',
        '  m_KeepAnimatorControllerStateOnDisable: 0'
    ]
    
    # 构建playerMovement组件部分
    player_movement_section = [
        f'--- !u!114 &{player_movement_file_id}',
        'MonoBehaviour:',
        '  m_ObjectHideFlags: 0',
        '  m_CorrespondingSourceObject: {fileID: 0}',
        '  m_PrefabInstance: {fileID: 0}',
        '  m_PrefabAsset: {fileID: 0}',
        '  m_GameObject: {fileID: 99808851631468291}',
        '  m_Enabled: 1',
        '  m_EditorHideFlags: 0',
        '  m_Script: {fileID: 11500000, guid: cfecf5634b91a774db4e4cfe948843f2, type: 3}',
        '  m_Name: ',
        '  m_EditorClassIdentifier: ',
        '  walkSpeed: 5',
        '  runSpeed: 8',
        '  jumpForce: 10',
        '  groundLayer: 0',
        '  groundCheckDistance: 0.1'
    ]
    
    # 构建CameraFollow组件部分
    camera_follow_section = [
        f'--- !u!114 &{camera_follow_file_id}',
        'MonoBehaviour:',
        '  m_ObjectHideFlags: 0',
        '  m_CorrespondingSourceObject: {fileID: 0}',
        '  m_PrefabInstance: {fileID: 0}',
        '  m_PrefabAsset: {fileID: 0}',
        '  m_GameObject: {fileID: 99808851631468291}',
        '  m_Enabled: 1',
        '  m_EditorHideFlags: 0',
        '  m_Script: {fileID: 11500000, guid: a12fa217c21343a4ab6ff0f79b91fea2, type: 3}',
        '  m_Name: ',
        '  m_EditorClassIdentifier: ',
        '  player: {fileID: 0}',
        '  followSpeed: 5',
        '  offset: {x: 0, y: 0, z: -10}',
        '  frameWidth: 4',
        '  frameHeight: 4',
        '  cameraSize: 5',
        '  constrainToIsland: 1'
    ]
    
    # 将新组件部分插入到合适位置（在Rigidbody2D之后）
    # 找到Rigidbody2D部分的位置
    rigidbody_idx = -1
    for i, section in enumerate(component_sections):
        if section[0].startswith('--- !u!50'):
            rigidbody_idx = i
            break
    
    if rigidbody_idx != -1:
        # 在Rigidbody2D之后插入新组件
        component_sections.insert(rigidbody_idx + 1, animator_section)
        component_sections.insert(rigidbody_idx + 2, player_movement_section)
        component_sections.insert(rigidbody_idx + 3, camera_follow_section)
    else:
        # 如果找不到，添加到末尾
        component_sections.append(animator_section)
        component_sections.append(player_movement_section)
        component_sections.append(camera_follow_section)
    
    # 重新构建内容
    new_content_lines = []
    for section in component_sections:
        new_content_lines.extend(section)
    
    new_content = '\n'.join(new_content_lines)
    
    # 写入文件
    output_dir = "/app/data/files/漂浮大陆/Assets/Prefabs"
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "Player.prefab")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"Player预制体已创建: {output_path}")
    return output_path

if __name__ == '__main__':
    create_player_prefab()