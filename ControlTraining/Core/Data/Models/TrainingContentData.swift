import Foundation

/// 训练内容数据提供者 - 提供预设的训练方法数据
struct TrainingContentData {
    
    /// 获取所有预设训练方法
    static func allTrainingMethods() -> [TrainingMethod] {
        return [
            kegelMethod(),
            stopStartMethod(),
            squeezeMethod(),
            breathingMethod(),
            pelvicFloorMethod()
        ]
    }
    
    /// 按分类获取训练方法
    static func methodsByCategory() -> [TrainingCategory: [TrainingMethod]] {
        Dictionary(grouping: allTrainingMethods(), by: { $0.category })
    }
    
    // MARK: - 凯格尔运动
    
    private static func kegelMethod() -> TrainingMethod {
        TrainingMethod(
            name: "凯格尔运动",
            category: .kegel,
            difficulty: .beginner,
            description: "凯格尔运动是通过有意识地收缩和放松骨盆底肌来增强肌肉力量的训练方法。该运动由阿诺德·凯格尔医生于1948年提出，是目前最广泛认可的控制力训练方法之一。通过规律练习，可以有效增强骨盆底肌群的力量和耐力，提升对射精反射的控制能力。",
            principle: "骨盆底肌（PC肌）是支撑盆腔器官的重要肌群，同时也参与射精反射的调控。当骨盆底肌力量不足时，难以在临近射精时有效抑制反射。凯格尔运动通过反复收缩-放松训练，增强PC肌的收缩力和持久力，使您能够在关键时刻主动收缩肌肉来延缓射精冲动。研究表明，持续8-12周的凯格尔训练可显著改善射精控制能力。",
            steps: [
                TrainingStep(order: 1, title: "定位骨盆底肌", instruction: "在排尿时尝试中途停止尿流，感受收缩的肌肉即为骨盆底肌（PC肌）。注意：此方法仅用于初次定位，不要频繁在排尿时练习，以免引起尿路问题。", duration: nil),
                TrainingStep(order: 2, title: "空收缩练习", instruction: "排空膀胱后，舒适地坐着或躺着。专注于骨盆底肌的位置，确保不收缩腹部、大腿或臀部肌肉。将手放在腹部确认腹部保持放松。", duration: 30),
                TrainingStep(order: 3, title: "慢速收缩", instruction: "缓慢收缩骨盆底肌，保持3秒钟。收缩时应感觉肌肉向上向内提起，而非向下用力。保持正常呼吸，不要屏气。", duration: 3),
                TrainingStep(order: 4, title: "缓慢放松", instruction: "缓慢放松骨盆底肌，保持3秒钟。放松和收缩同等重要，确保肌肉完全放松后再进行下一次收缩。", duration: 3),
                TrainingStep(order: 5, title: "重复练习", instruction: "重复收缩-放松循环10次为一组。每组之间休息30秒。初期每天完成3组，随着力量增强可逐渐增加至每天5组。", duration: 60),
                TrainingStep(order: 6, title: "快速收缩", instruction: "在完成慢速收缩后，进行快速收缩练习：快速收缩骨盆底肌1秒后立即放松，重复10次。这有助于训练肌肉的快速反应能力，在实际训练中能更快地响应控制需求。", duration: 30)
            ],
            precautions: [
                "不要在排尿时频繁练习，仅用于初次定位肌肉",
                "收缩时保持正常呼吸，不要屏气",
                "确保只收缩骨盆底肌，不收缩腹部、大腿或臀部",
                "如感到不适或疼痛，应立即停止并咨询医生",
                "建议空腹或饭后1小时再练习",
                "坚持每天练习，8-12周后可见明显效果",
                "初期不要过度用力，循序渐进增加强度"
            ],
            expectedEffect: "持续练习8-12周后，可显著增强骨盆底肌力量，提升射精控制能力。研究显示，约70%的练习者在规律训练后报告控制力明显改善。同时还有助于改善尿失禁和提升性功能质量。",
            targetAudience: "所有成年男性，尤其适合初学者和骨盆底肌力量较弱者。无特殊身体条件限制，可随时随地进行练习。",
            defaultDuration: 300
        )
    }
    
    // MARK: - 停-动技术
    
    private static func stopStartMethod() -> TrainingMethod {
        TrainingMethod(
            name: "停-动技术",
            category: .stopStart,
            difficulty: .intermediate,
            description: "停-动技术（Stop-Start Technique）是一种行为训练方法，通过在刺激接近射精阈值时主动暂停刺激，待兴奋度降低后重新开始，从而逐步提高射精阈值。该方法由泌尿科医生詹姆斯·塞曼斯于1956年提出，是行为疗法中的经典方法。",
            principle: "射精反射遵循一定的兴奋度阈值规律。当性刺激累积到一定阈值时，射精反射将不可逆地触发。停-动技术通过在兴奋度接近但未达到阈值时主动暂停，让兴奋度自然回落，反复训练后可逐步提高射精阈值，延长控制时间。这类似于运动员通过间歇训练提高耐力阈值的原理。",
            steps: [
                TrainingStep(order: 1, title: "自我评估准备", instruction: "在开始训练前，先了解自己的兴奋度变化规律。将兴奋度分为1-10级：1为完全平静，10为射精。注意感受在哪个级别（通常为7-8级）时出现射精预感。", duration: nil),
                TrainingStep(order: 2, title: "开始刺激", instruction: "以舒适的节奏开始自我刺激。注意专注于感受身体的变化，特别是兴奋度的逐渐上升。保持放松的心态，不要过于紧张或焦虑。", duration: 120),
                TrainingStep(order: 3, title: "识别临界点", instruction: "当兴奋度达到7-8级时，你会感受到射精预感——会阴部肌肉开始收缩、呼吸加快。此时是停止的最佳时机。不要等到9级才停止，那时射精反射可能已经难以控制。", duration: nil),
                TrainingStep(order: 4, title: "主动暂停", instruction: "一旦感受到射精预感，立即停止所有刺激。可以配合深呼吸来帮助放松。将注意力从刺激感转移到呼吸上，缓慢深吸气4秒，屏气2秒，缓慢呼气6秒。", duration: 30),
                TrainingStep(order: 5, title: "等待兴奋度下降", instruction: "暂停期间保持放松，等待兴奋度从7-8级下降到5级左右。通常需要15-30秒。不要急于重新开始，确保兴奋度有明显下降。", duration: 30),
                TrainingStep(order: 6, title: "重新开始", instruction: "当兴奋度降至5级左右时，重新开始刺激。注意保持与之前相同的节奏。重复步骤3-5，每次训练完成3-4个停-动循环。", duration: 120),
                TrainingStep(order: 7, title: "结束训练", instruction: "完成3-4个停-动循环后，可以选择结束训练或允许射精。建议初期训练以完成循环为主，逐步增加循环次数。记录每次训练的循环次数和控制时间，观察进步。", duration: nil)
            ],
            precautions: [
                "训练时保持放松心态，焦虑会影响训练效果",
                "不要等到射精冲动非常强烈时才停止，应在预感出现时立即暂停",
                "暂停期间不要进行任何形式的刺激",
                "初期可能难以准确判断兴奋度级别，需要多次练习来提升感知能力",
                "建议每周练习2-3次，避免过于频繁",
                "如果在暂停后仍无法控制，不要气馁，这是正常的学习过程",
                "有伴侣时，建议先单独练习掌握技巧后再与伴侣一起练习"
            ],
            expectedEffect: "经过4-6周的规律练习，大多数用户可以显著延长控制时间，学会更准确地感知和控制射精冲动。研究表明，停-动技术的有效率约为50-60%，配合其他训练方法效果更佳。",
            targetAudience: "有一定训练基础的男性，已掌握基本的骨盆底肌控制能力。适合能够准确感知自身兴奋度变化的用户。不建议完全没有训练经验者直接使用。",
            defaultDuration: 600
        )
    }
    
    // MARK: - 挤压技术
    
    private static func squeezeMethod() -> TrainingMethod {
        TrainingMethod(
            name: "挤压技术",
            category: .squeeze,
            difficulty: .intermediate,
            description: "挤压技术（Squeeze Technique）由泌尿科医生威廉·马斯特斯和弗吉尼亚·约翰逊提出，是在停-动技术基础上发展而来的行为训练方法。通过在接近射精阈值时对阴茎特定部位施加压力，直接抑制射精反射，效果比停-动技术更为直接。",
            principle: "阴茎冠状沟和系带区域分布着密集的神经末梢，对这些区域施加适度压力可以暂时抑制射精反射的神经传导。挤压技术利用这一生理机制，在兴奋度接近阈值时通过物理按压来降低兴奋度，从而延长控制时间。与停-动技术相比，挤压技术能更快速地降低兴奋度。",
            steps: [
                TrainingStep(order: 1, title: "了解挤压位置", instruction: "挤压位置在阴茎冠状沟（龟头后方的凸起边缘）和系带（龟头下方的皮肤褶皱）区域。用拇指和食指找到这两个位置，感受其敏感度。", duration: nil),
                TrainingStep(order: 2, title: "开始刺激", instruction: "与停-动技术类似，以舒适的节奏开始自我刺激。专注于感受兴奋度的变化，当兴奋度达到7-8级时准备进行挤压。", duration: 120),
                TrainingStep(order: 3, title: "识别射精预感", instruction: "当感受到射精预感（兴奋度7-8级）时，立即停止刺激。注意与停-动技术相同，不要等到冲动过于强烈才行动。", duration: nil),
                TrainingStep(order: 4, title: "执行挤压", instruction: "用拇指放在系带位置，食指放在冠状沟对面位置，两者对向施加适度压力。力度以感到明显压迫但不疼痛为宜。保持挤压15-20秒，或直到射精冲动消退。", duration: 20),
                TrainingStep(order: 5, title: "释放压力", instruction: "缓慢释放挤压压力，等待15-30秒让兴奋度充分下降。注意感受挤压后兴奋度的变化，通常挤压后兴奋度会下降至4-5级。", duration: 30),
                TrainingStep(order: 6, title: "重新开始", instruction: "兴奋度下降后重新开始刺激。每次训练完成3-4个挤压循环。随着训练进展，你会发现自己需要的挤压次数逐渐减少，控制时间逐渐延长。", duration: 120),
                TrainingStep(order: 7, title: "记录与评估", instruction: "每次训练后记录挤压次数、控制时间和兴奋度变化。定期回顾训练记录，评估进步情况。如果发现需要挤压的次数减少，说明控制能力在提升。", duration: nil)
            ],
            precautions: [
                "挤压力度要适中，过重可能造成疼痛或损伤，过轻则效果不明显",
                "不要在勃起最强烈时挤压，应在射精预感出现但尚未不可控时进行",
                "指甲应修剪整齐，避免划伤皮肤",
                "如有疼痛或不适，立即停止挤压",
                "挤压后可能出现短暂的勃起硬度下降，这是正常现象",
                "建议与凯格尔运动结合练习，增强整体控制能力",
                "不建议在射精即将发生时强行挤压，可能造成逆行射精"
            ],
            expectedEffect: "经过4-8周规律练习，可以有效提高射精阈值，延长控制时间。研究显示挤压技术的有效率约为60-70%，略高于停-动技术。与骨盆底肌训练结合使用效果更佳。",
            targetAudience: "已掌握停-动技术基础的中级训练者。需要能够准确判断射精预感时机。有伴侣协助练习时效果更好，但也可单独练习。",
            defaultDuration: 600
        )
    }
    
    // MARK: - 呼吸训练
    
    private static func breathingMethod() -> TrainingMethod {
        TrainingMethod(
            name: "呼吸训练",
            category: .breathing,
            difficulty: .beginner,
            description: "呼吸训练是通过调节呼吸模式来控制性兴奋度的方法。深慢呼吸可以激活副交感神经系统，降低心率和血压，从而帮助延缓射精。这是最安全的训练方法之一，无任何副作用，且可与其他训练方法完美配合使用。",
            principle: "自主神经系统分为交感神经和副交感神经。性兴奋和射精主要由交感神经驱动，而深慢呼吸可以激活副交感神经，产生放松效应，抑制交感神经的过度兴奋。通过有意识地控制呼吸节奏，可以在兴奋度过高时有效降低兴奋度，维持更长时间的控制。研究证实，腹式深呼吸可使心率降低10-15%，显著延缓射精反射。",
            steps: [
                TrainingStep(order: 1, title: "腹式呼吸基础", instruction: "舒适地坐着或躺着，一手放在胸前一手放在腹部。通过鼻子缓慢吸气4秒，感受腹部隆起（而非胸部），然后缓慢呼气6秒。确保呼气时间长于吸气时间，这有助于激活副交感神经。", duration: 120),
                TrainingStep(order: 2, title: "4-2-6呼吸法", instruction: "按照4秒吸气、2秒屏气、6秒呼气的节奏进行呼吸。吸气时默数1-4，屏气时默数1-2，呼气时默数1-6。这种呼吸模式可以有效激活副交感神经，产生深度放松效果。", duration: 180),
                TrainingStep(order: 3, title: "放松呼吸练习", instruction: "在完全放松的状态下练习4-2-6呼吸法10分钟。专注于呼吸的节奏和身体的感觉，感受每次呼气时身体的放松。这是建立呼吸控制基础的重要步骤。", duration: 600),
                TrainingStep(order: 4, title: "兴奋时呼吸控制", instruction: "在感到兴奋度上升时，立即切换到4-2-6呼吸模式。将注意力从刺激感转移到呼吸节奏上，感受每次呼气带来的放松。保持这个呼吸节奏直到兴奋度明显下降。", duration: 120),
                TrainingStep(order: 5, title: "结合骨盆底肌练习", instruction: "在呼气时收缩骨盆底肌3秒，吸气时放松。这种结合练习可以同时增强呼吸控制和肌肉控制能力。每次练习完成10个呼吸-收缩循环。", duration: 180),
                TrainingStep(order: 6, title: "日常呼吸训练", instruction: "每天进行5-10分钟的呼吸训练，不需要在性相关场景下练习。可以在起床后、午休时或睡前进行。持续日常练习可以增强对呼吸模式的掌控，在需要时更容易切换到控制呼吸模式。", duration: 300)
            ],
            precautions: [
                "呼吸训练应在安静、舒适的环境中进行",
                "不要过度深呼吸，可能导致头晕或过度换气",
                "如有呼吸系统疾病，请先咨询医生",
                "练习时保持放松姿势，避免肌肉紧张",
                "呼吸节奏应自然流畅，不要强行憋气",
                "饭后30分钟内不宜进行深度呼吸练习",
                "呼吸训练可随时随地进行，是其他训练方法的最佳辅助"
            ],
            expectedEffect: "持续练习2-4周后，可以显著提升对呼吸模式的控制能力，在兴奋时能够快速切换到控制呼吸模式。呼吸训练的即时效果明显，可在训练过程中实时降低兴奋度。长期练习还可以减轻焦虑、改善睡眠质量。",
            targetAudience: "所有成年男性，特别适合初学者和容易焦虑紧张者。呼吸训练是最安全的入门方法，无任何身体条件限制，也适合与其他训练方法配合使用。",
            defaultDuration: 420
        )
    }
    
    // MARK: - 骨盆底肌训练
    
    private static func pelvicFloorMethod() -> TrainingMethod {
        TrainingMethod(
            name: "骨盆底肌综合训练",
            category: .pelvicFloor,
            difficulty: .advanced,
            description: "骨盆底肌综合训练是在凯格尔运动基础上发展的高级训练方法，包含多种收缩模式、耐力训练和功能性训练。该方法不仅增强肌肉力量，更注重肌肉的协调性、耐力和功能性控制能力，适合已掌握基础凯格尔运动的进阶训练者。",
            principle: "骨盆底肌群由多层肌肉组成，不同肌肉纤维承担不同功能。慢肌纤维负责持久支撑，快肌纤维负责快速收缩和反射控制。基础凯格尔运动主要训练慢肌纤维的持久力，而综合训练则同时针对慢肌纤维和快肌纤维，通过多种收缩模式全面提升肌肉的功能性控制能力，使您在不同强度和节奏的刺激下都能有效控制射精反射。",
            steps: [
                TrainingStep(order: 1, title: "热身放松", instruction: "先进行2分钟的腹式深呼吸，放松全身肌肉。然后轻柔地收缩和放松骨盆底肌5次作为热身，每次收缩保持2秒。这有助于唤醒肌肉感知，为后续训练做准备。", duration: 120),
                TrainingStep(order: 2, title: "耐力收缩训练", instruction: "收缩骨盆底肌并保持10秒，然后放松10秒。重复10次为一组，完成3组。确保收缩时保持正常呼吸，不要屏气。这种训练主要增强慢肌纤维的耐力，提升持久控制能力。", duration: 200),
                TrainingStep(order: 3, title: "阶梯式收缩", instruction: "分3个阶段逐步增加收缩力度：轻度收缩（30%力度）保持5秒→中度收缩（60%力度）保持5秒→全力收缩（100%力度）保持5秒，然后分3个阶段逐步放松。重复5次。这种训练增强肌肉的精细控制能力。", duration: 150),
                TrainingStep(order: 4, title: "快速反射训练", instruction: "快速全力收缩骨盆底肌1秒后立即放松，休息2秒后重复。连续完成20次。这种训练主要针对快肌纤维，提升肌肉对射精反射的快速抑制能力，是实际控制中最关键的技能。", duration: 60),
                TrainingStep(order: 5, title: "功能性模拟训练", instruction: "模拟实际场景中的控制过程：开始轻度收缩（30%）→逐渐增强至中度（60%）→在模拟兴奋度上升时快速全力收缩（100%）保持5秒→缓慢放松。重复5次，每次间隔30秒。", duration: 120),
                TrainingStep(order: 6, title: "协调性训练", instruction: "骨盆底肌收缩与呼吸协调练习：吸气时放松骨盆底肌，呼气时收缩骨盆底肌。按照4秒吸气-6秒呼气的节奏进行，完成10个循环。这种训练增强呼吸与肌肉控制的协调性。", duration: 100),
                TrainingStep(order: 7, title: "放松恢复", instruction: "训练结束后，进行2分钟的放松呼吸。轻柔地按摩下腹部和会阴区域，帮助肌肉放松恢复。注意感受训练后肌肉的疲劳感，这是训练有效的标志。", duration: 120)
            ],
            precautions: [
                "必须先掌握基础凯格尔运动至少4周后才能开始此训练",
                "训练中如感到疼痛或不适，应立即停止",
                "不要过度训练，每天1-2次即可，肌肉需要恢复时间",
                "确保能准确区分骨盆底肌与其他肌肉的收缩",
                "快速反射训练初期可能难以完成20次，可从10次开始逐步增加",
                "训练后可能出现肌肉酸痛，属于正常现象，1-2天内应消退",
                "如有骨盆底肌功能障碍史，请先咨询医生",
                "建议在专业指导下进行功能性模拟训练"
            ],
            expectedEffect: "持续练习8-12周后，可以显著提升骨盆底肌的力量、耐力和协调性。快肌纤维的反应速度提升，能在射精预感出现时更快速有效地抑制反射。综合训练比基础凯格尔运动的效果更全面，研究显示综合训练可将控制时间延长2-3倍。",
            targetAudience: "已持续练习凯格尔运动4周以上的进阶训练者。需要能够准确控制骨盆底肌收缩力度和节奏。不适合初学者或骨盆底肌力量不足者直接使用。",
            defaultDuration: 900
        )
    }
}