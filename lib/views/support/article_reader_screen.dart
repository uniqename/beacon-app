import 'package:flutter/material.dart';
import '../../config/org_config.dart';
import '../../services/app_config_service.dart';
import 'content_library_screen.dart';

class ArticleReaderScreen extends StatefulWidget {
  final EducationalContent content;

  const ArticleReaderScreen({super.key, required this.content});

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  double _fontSize = 16;

  OrgConfig get _cfg => AppConfigService.instance.config;
  bool get _isUs => _cfg.orgKey == 'us';
  Color get _accent =>
      _isUs ? const Color(0xFF1E4D8C) : Colors.indigo[700]!;

  // Placeholder — import if available
  // ignore: unused_element
  Color _catColor(String cat) => Colors.indigo[700]!;

  @override
  Widget build(BuildContext context) {
    final content = widget.content;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          content.category,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        backgroundColor: _accent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease, color: Colors.white),
            tooltip: 'Smaller text',
            onPressed: () {
              if (_fontSize > 12) setState(() => _fontSize -= 2);
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, color: Colors.white),
            tooltip: 'Larger text',
            onPressed: () {
              if (_fontSize < 26) setState(() => _fontSize += 2);
            },
          ),
          IconButton(
            icon: Icon(
              content.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () => setState(() {
              content.isFavorite = !content.isFavorite;
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              content.title,
              style: TextStyle(
                fontSize: _fontSize + 10,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),

            // Meta row
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(content.duration,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 16),
                Icon(Icons.flag_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(_isUs ? 'United States' : 'Ghana',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // Article body
            Text(
              _articleBody(content.id),
              style: TextStyle(
                  fontSize: _fontSize, height: 1.7, color: Colors.grey[800]),
            ),
            const SizedBox(height: 36),

            // Support callout
            _buildSupportBox(),
            const SizedBox(height: 32),

            // Related articles
            Text(
              'Related Articles',
              style: TextStyle(
                  fontSize: _fontSize + 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._related(content.id).map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(Icons.article_outlined, color: _accent),
                  title: Text(r['title']!,
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(r['category']!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                  trailing:
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                  onTap: () {
                    // Find the content in the catalogue and open it
                    final match = catalogue.where(
                        (c) => c.id == r['id']).toList();
                    if (match.isNotEmpty && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ArticleReaderScreen(content: match.first),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Support callout ─────────────────────────────────────────────────────

  Widget _buildSupportBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 10),
              const Text(
                'Need Support?',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isUs
                ? "If you're in immediate danger, call 911. For confidential support, call the National DV Hotline: ${_cfg.dvHotline}."
                : "If you're in immediate danger, call 999. For DV support, contact ${_cfg.dvHotlineLabel}: ${_cfg.dvHotline}.",
            style: TextStyle(color: Colors.amber[900], fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/emergency_contacts'),
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('View Emergency Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Article bodies ──────────────────────────────────────────────────────

  String _articleBody(String id) {
    switch (id) {
      case 'understanding_dv':
        return _isUs ? _understandingDvUs() : _understandingDvGh();
      case 'safety_plan':
        return _safetyPlan();
      case 'self_care_crisis':
        return _selfCare();
      case 'healing_trauma':
        return _healingTrauma();
      case 'financial_independence':
        return _isUs ? _financialUs() : _financialGh();
      case 'children_trauma':
        return _childrenTrauma();
      case 'cycle_of_abuse':
        return _cycleOfAbuse();
      case 'healthy_relationships':
        return _healthyRelationships();
      case 'legal_rights_gh':
        return _legalGh();
      case 'dovvsu_guide':
        return _dovvsuGuide();
      case 'ark_foundation':
        return _shelterGh();
      case 'customary_law_gh':
        return _customaryLawGh();
      case 'legal_rights_us':
        return _legalUs();
      case 'protective_orders_us':
        return _protectiveOrdersUs();
      case 'immigrant_rights_us':
        return _immigrantRightsUs();
      case 'finding_shelter_us':
        return _findingShelterUs();
      case 'safety_tech_us':
        return _safetyTechUs();
      default:
        return 'This article is being prepared. Please check back soon.\n\nIn the meantime, if you need immediate support, contact ${_cfg.dvHotlineLabel} at ${_cfg.dvHotline}.';
    }
  }

  // ── Universal articles ───────────────────────────────────────────────────

  String _safetyPlan() => '''A safety plan is a personalised, practical guide for staying safer in an abusive situation and preparing to leave when the time is right.

Why You Need a Safety Plan

Leaving an abusive relationship is often the most dangerous time. A plan helps you act quickly without having to think under pressure.

Step 1 — Identify Safe People
• Who can you call at any hour?
• Who will believe you and keep your confidence?
• Memorise at least two phone numbers.

Step 2 — Important Documents
Gather copies of: ID or passport, birth certificates, immigration documents, financial records, medical records. Store them with a trusted person or in a safe location outside the home.

Step 3 — Emergency Bag
Pack a bag you can grab quickly:
• Money or a debit card
• Phone charger
• Medication
• Clothing for a few days
• Documents

Step 4 — Know Your Exit Routes
• Which door will you use?
• Where will you go immediately?
• How will you get there?

Step 5 — Code Word
Establish a code word with a trusted friend or family member. When you say it, they call for help.

Step 6 — Digital Safety
• Change passwords on all accounts
• Use a device the abuser cannot access
• Clear your browser history if needed

Step 7 — After You Leave
• Contact a shelter or DV hotline immediately
• Apply for a protective order
• Inform your children's school if applicable

Remember: You are not alone. Help is available.''';

  String _selfCare() => '''Crisis situations deplete your emotional and physical resources. Self-care is not selfish — it is how you survive and rebuild.

Understanding Stress Responses

Trauma activates your nervous system's fight-or-flight response. You may feel anxious, numb, exhausted, or unable to concentrate. These are normal reactions to an abnormal situation.

Simple Daily Practices

Breathing
Slow, deep breaths signal safety to your nervous system. Try: inhale for 4 counts, hold for 4, exhale for 6. Repeat five times.

Movement
Even a short walk can shift your mood. Gentle stretching, dancing to a song you love, or any movement that feels good to your body.

Sleep
Try to keep regular sleep times. A consistent routine — even small rituals like washing your face before bed — signals your brain that it is safe to rest.

Nourishment
Eat regularly even when you have no appetite. Simple, familiar foods are fine.

Connection
Isolation amplifies pain. Even a brief conversation with someone safe — a friend, a family member, a counsellor — can help.

Boundaries
It is okay to say no. Protecting your energy is not weakness.

When to Seek Professional Help

Consider talking to a counsellor or therapist if you experience:
• Persistent nightmares or flashbacks
• Feeling detached from yourself or surroundings
• Inability to feel positive emotions
• Thoughts of harming yourself

You deserve support — reaching out is a sign of strength.''';

  String _healingTrauma() => '''Healing from trauma is not a straight line. It takes time, support, and patience with yourself.

What Happens in the Brain After Trauma

Traumatic experiences can alter how the brain processes memories and threat. The amygdala (threat detector) becomes hyperactive; the prefrontal cortex (rational thinking) becomes less effective. This is why trauma survivors may feel "stuck" in fear or reactivity long after the danger has passed.

Stages of Recovery

1. Safety and Stabilisation
Before processing trauma, you must first feel physically and emotionally safe. This means having a stable living situation, supportive relationships, and basic coping tools.

2. Remembering and Mourning
With professional support, survivors can begin to process traumatic memories — understanding what happened and grieving what was lost.

3. Reconnection
Rebuilding your identity, relationships, and sense of future. This does not mean returning to who you were before — often survivors discover new strength and purpose.

Evidence-Based Approaches

• Trauma-Informed Counselling
• Cognitive Behavioural Therapy (CBT)
• EMDR (Eye Movement Desensitisation and Reprocessing)
• Somatic therapies (body-based healing)
• Group support with other survivors

What Helps Day-to-Day

• Routine and predictability
• Time in nature
• Creative expression (writing, art, music)
• Physical activity
• Spiritual or community practice
• Limiting news and social media if they re-traumatise

You survived something very difficult. Healing is possible — and you do not have to do it alone.''';

  String _cycleOfAbuse() => '''Most abusive relationships follow a recognisable cycle. Understanding it can help you see patterns you may have dismissed or explained away.

The Four Phases

1. Tension Building
Small incidents accumulate. The survivor walks on eggshells, trying to manage the abuser's mood. Conflict feels inevitable.

Signs: Increased criticism, moodiness, silent treatment, minor controlling behaviour.

2. Acute Explosion
A serious incident of abuse occurs — physical, sexual, emotional, or a combination.

3. Reconciliation (the "Honeymoon" Phase)
The abuser apologises, promises to change, shows affection or remorse, gives gifts. The survivor may feel hope that things will improve.

Important: This phase is part of the abuse, not evidence that the relationship is healthy.

4. Calm
A period of relative peace. Life may feel almost normal. Both partners may minimise what happened.

Then tension begins to build again.

Why Leaving Is Complicated

• You love the person in the honeymoon phase — not just the abuser.
• Leaving is statistically the most dangerous time.
• Abusers often control finances, housing, and social networks.
• Children, faith, cultural expectations, and fear of disbelief all play a role.

None of this is your fault. The cycle is designed to keep you trapped.

Breaking the Cycle

The cycle does not break on its own. Research consistently shows that abuse escalates in frequency and severity over time without intervention. Safety planning and professional support can help you find a way out.''';

  String _healthyRelationships() => '''Not everyone has had a model of a healthy relationship to compare their own experience to. Here is what one looks like.

The Equality Wheel

Healthy relationships are built on equality — both partners have equal power and respect.

Respect
• Listening without interrupting or mocking
• Valuing each other's opinions
• Being emotionally affirming

Trust and Support
• Believing each other
• Supporting each other's goals
• Respecting the right to feelings

Honesty and Accountability
• Communicating openly
• Admitting mistakes without blaming the other person

Shared Responsibility
• Household and parenting decisions made together
• Neither partner dominates

Economic Partnership
• Financial decisions made jointly
• Neither partner controls money as a power tool

Negotiation and Fairness
• Conflict resolved through discussion and compromise
• Willingness to change when needed

Non-Threatening Behaviour
• Feeling safe to express yourself
• Disagreements stay verbal — no threats, intimidation, or physical contact

Signs You Are in a Healthy Relationship

• You feel safe, respected, and heard.
• You can spend time with friends and family freely.
• You can disagree without fear of consequences.
• You feel free to be yourself.
• Decisions are made together.

If any of these are absent, it is worth exploring why — and seeking support.''';

  String _childrenTrauma() => '''Children who witness domestic violence are directly harmed — even if they are never physically hurt themselves. Your instinct to protect them is right, and there are things you can do.

How Children Are Affected

Young children (0–5): Regression in development, clinginess, nightmares, difficulty eating.

School-age (6–12): Declining grades, difficulty concentrating, headaches and stomach aches with no physical cause, social withdrawal, blaming themselves.

Teenagers: Risky behaviour, aggression, depression, running away, substance use. Some replicate relationship patterns they witnessed.

What Children Need Most

• Safety — to be physically safe and to feel it.
• Honesty — age-appropriate explanations. "What happened was not your fault. It was not your job to stop it."
• Consistency — routine reassures a dysregulated nervous system.
• Connection — your calm, present attention is the most powerful intervention.
• Permission to feel — naming feelings helps children process them.

What Not to Do

• Do not put children in the middle of adult conflict.
• Do not use children to send messages to the other parent.
• Do not speak negatively about the other parent in front of them — even if it is true.
• Do not dismiss their fears or grief.

When to Seek Professional Help

Signs a child needs specialised support: persistent nightmares, self-harm, statements about not wanting to live, aggression toward others, inability to function at school.

A trauma-informed therapist who works with children can help significantly. You do not have to navigate this alone.''';

  // ── Ghana articles ────────────────────────────────────────────────────────

  String _understandingDvGh() => '''Domestic violence is a serious issue affecting many families across Ghana. Understanding the signs and knowing your rights is the first step toward safety.

What the Law Says

Ghana's Domestic Violence Act 2007 (Act 732) defines domestic violence broadly to include:
• Physical abuse
• Sexual abuse
• Economic abuse (controlling money, preventing employment)
• Emotional and psychological abuse
• Intimidation and harassment

The law applies within the home — including between spouses, partners, parents and children, and extended family members living together.

Recognising the Warning Signs

• Your partner is extremely jealous or possessive
• You feel afraid of your partner's reaction
• Your partner controls where you go, who you see, or how you spend money
• You have been threatened, humiliated, or intimidated
• Your partner blames you for their abusive behaviour

The Cycle of Violence

Many abusive relationships follow a pattern: tension builds → an incident of violence occurs → the abuser apologises and promises change → a period of calm → tension builds again. Without intervention, the cycle typically escalates.

You Have the Right to

• Report abuse to the police
• Seek a protection order from the courts
• Access shelter and support services
• Pursue criminal charges against your abuser

The Domestic Violence and Victim Support Unit (DOVVSU) is available at all police stations in Ghana. Officers are trained to handle DV cases with confidentiality.

Where to Get Help

• DOVVSU: 0800800800 (free and confidential)
• Ghana Police Service: 191
• Ark Foundation Ghana: Shelter and support
• WiLDAF-Ghana: Legal assistance
• Oasis Ghana: Counselling and support

Remember: The abuse is not your fault. Help is available.''';

  String _legalGh() => '''Ghana's Domestic Violence Act 732 (2007) is one of the strongest DV protection laws in West Africa. Here is what it means for you.

What the Act Covers

The Act defines domestic violence to include physical, sexual, economic, and emotional abuse committed within a domestic relationship — including marriage, cohabitation, dating relationships, and family members living together.

Protection Orders

You can apply for a Protection Order at any District Court. The order can:
• Prohibit the abuser from contacting you
• Remove the abuser from a shared home
• Grant you temporary custody of children
• Order the abuser to pay maintenance or repair damages

You do not need a lawyer to apply. DOVVSU officers can help you with the process.

Criminal Charges

Domestic violence is a criminal offence under Act 732. If you report to the police, the abuser can be arrested, charged, and prosecuted. Penalties include fines and imprisonment.

How to Report

1. Go to the nearest police station and ask for the DOVVSU desk.
2. Bring any evidence: photographs, medical reports, witness names.
3. A police officer will take your statement and advise you on next steps.
4. You can report anonymously if you are not yet ready to pursue charges.

Emergency Shelter

• Ark Foundation Ghana: Accra — 030 277 5975
• Oasis Ghana: Accra — counselling and support
• FIDA Ghana: Legal aid for women

Support Organisations

• WiLDAF-Ghana: Legal advocacy and education
• LAWA Ghana: Women's legal rights
• Department of Social Welfare: Family support services

You do not have to face this alone. The law is on your side.''';

  String _dovvsuGuide() => '''The Domestic Violence and Victim Support Unit (DOVVSU) is a dedicated unit of the Ghana Police Service. It exists specifically to help you.

What is DOVVSU?

DOVVSU was established to provide a professional, sensitive response to cases of domestic violence, child abuse, and sexual offences. Officers are specially trained in trauma-informed interviewing and case management.

DOVVSU is available at police stations across Ghana, including in all regional capitals and many district stations.

What to Expect When You Visit

• You will speak with a trained officer in a private setting.
• Your statement will be recorded confidentially.
• The officer will explain your options — reporting, applying for a protection order, or seeking referrals.
• You will not be judged or pressured.

You can bring a support person — a friend, family member, or counsellor.

What DOVVSU Can Do

• Take your statement
• Arrest and charge the abuser
• Refer you to medical care, shelter, or legal aid
• Help you apply for a Protection Order
• Connect you with social welfare services

What to Bring

• Any evidence: photographs, medical records, texts, call logs
• Names of witnesses if any
• Any documents related to your case

You do not need to have visible injuries to report. Emotional, sexual, and economic abuse are all covered by the law.

Contact

• Hotline: 0800800800 (toll-free, 24/7)
• Available at all police stations — ask for the DOVVSU desk

It is never too late to report.''';

  String _shelterGh() => '''If you need to leave home quickly, these organisations provide shelter, support, and legal assistance across Ghana.

Ark Foundation Ghana
The Ark Foundation provides shelter for women and children fleeing domestic violence, as well as counselling, legal aid, and reintegration support.
• Phone: 030 277 5975
• Location: Accra

Oasis Ghana
Oasis provides trauma counselling, safe spaces, and community support for survivors of gender-based violence.
• Location: Accra

WiLDAF-Ghana (Women in Law and Development in Africa)
Legal education, advocacy, and advice for women across Ghana.
• Phone: 030 255 1394
• Services: Legal aid, awareness campaigns, paralegal support

FIDA Ghana (International Federation of Women Lawyers)
Free legal aid and representation for women who cannot afford a lawyer.
• Phone: 030 221 1681
• Services: Court representation, mediation, legal advice

Department of Social Welfare
The DSW provides family support, child protection, and can arrange temporary care for children in crisis situations.
• Available at all district offices across Ghana

How to Access Shelter Quickly

1. Call DOVVSU on 0800800800 — they can coordinate referrals to shelter.
2. Contact one of the organisations above directly.
3. Speak to a healthcare worker at a hospital or clinic — they are mandated to refer DV survivors to support services.

You do not need money to access these services. Most are free of charge.''';

  String _customaryLawGh() => '''Ghana has a dual legal system — statutory law (Acts of Parliament) and customary law (traditional practices). Understanding how they interact is important for DV survivors.

Where Statutory Law Prevails

The Domestic Violence Act 732 (2007) is statutory law. It applies to all persons in Ghana regardless of ethnicity, religion, or traditional affiliation. Where there is a conflict between customary law and the DV Act, the DV Act prevails.

This means:
• A husband has no legal right to beat his wife under any customary law in Ghana.
• Forced marriage is not protected by customary law.
• Sexual violence within marriage is a criminal offence.

Common Customary Pressures Survivors Face

• Being told to "settle the matter at home" through family mediation
• Extended family discouraging reporting to avoid shame
• Pressure to stay in the marriage for the sake of children or property
• Bride price (dowry) being cited as giving a husband control

Your Rights

Family mediation is not the same as criminal justice. You have the right to:
• Report to the police regardless of what your family, in-laws, or community leaders say
• Refuse to participate in mediation if you feel unsafe
• Seek a protection order from a formal court

Seeking Help Despite Community Pressure

It can feel deeply isolating to act against family or community expectations. Organisations like WiLDAF-Ghana and FIDA Ghana specifically support women navigating these pressures. Speaking with a counsellor at DOVVSU or a legal aid provider can help you understand your options in confidence.

Your safety matters more than cultural expectations. The law agrees.''';

  // ── US articles ──────────────────────────────────────────────────────────

  String _understandingDvUs() => '''Domestic violence affects people of every race, age, income level, religion, and gender. Understanding it clearly is the first step to safety.

What Counts as Domestic Violence

Domestic violence is a pattern of behaviour used to gain or maintain power and control over an intimate partner or family member. It includes:

• Physical abuse: hitting, pushing, choking, or any physical harm
• Emotional/psychological abuse: intimidation, isolation, threats, humiliation
• Economic abuse: controlling finances, preventing work, creating debt
• Sexual abuse: any unwanted sexual contact or coercion
• Technology abuse: stalking via phone, GPS, or social media
• Reproductive coercion: tampering with contraception, pressuring about pregnancy

Recognising Warning Signs

Early in a relationship:
• Moves very fast — intense affection, wanting to move in quickly
• Extreme jealousy presented as love
• Criticising your friends or family
• Monitoring your phone or social media

As the relationship continues:
• You walk on eggshells around their moods
• You feel afraid to express opinions
• You make excuses for their behaviour to others
• Your access to money has been restricted

Your Legal Rights Under Federal Law

The Violence Against Women Act (VAWA) provides:
• Federal domestic violence crimes and penalties
• Funding for shelters, hotlines, and legal aid
• Immigration protections for survivor spouses and partners (VAWA self-petition)
• Housing protections (you cannot be evicted solely because you are a DV victim)

Every state also has its own DV statutes, mandatory arrest policies, and victim protection programmes.

Where to Get Help (24/7)

• National Domestic Violence Hotline: 1-800-799-7233 (TTY: 1-800-787-3224)
• Text START to 88788
• Chat: thehotline.org
• RAINN (sexual assault): 1-800-656-4673
• Crisis Text Line: Text HOME to 741741

Help is available in over 200 languages. You do not have to face this alone.''';

  String _legalUs() => '''Federal and state laws provide powerful protections for domestic violence survivors in the United States. Here is what you need to know.

Federal Law — VAWA

The Violence Against Women Act (VAWA), most recently reauthorised in 2022, provides:

• Federal domestic violence crimes and penalties
• Protections for LGBTQ+ survivors
• Confidentiality requirements for survivor information
• Immigration relief (VAWA self-petition, U visa, T visa)
• Housing protections — landlords cannot evict solely based on DV victim status
• Tribal protections for Native American women

State Laws

Every state has domestic violence statutes that may provide:
• Mandatory arrest laws (police must arrest if probable cause exists)
• No-drop prosecution policies
• Protective orders (civil and criminal)
• Mandatory DV training for police, judges, and medical staff
• Compensation funds for crime victims

Protective Orders

A protective order (also called a restraining order, order of protection) is a civil court order that can:
• Prohibit the abuser from contacting or approaching you
• Remove the abuser from a shared home
• Grant temporary child custody and support
• Be enforced by police — violation is a criminal offence

You can apply for an emergency (ex parte) order without the abuser present, often the same day you file.

How to Access Legal Help

• Call the National DV Hotline (1-800-799-7233) for referrals in your area
• Contact your local Legal Aid office — free legal representation for income-qualifying survivors
• Many family courts have self-help centres to assist with protective orders
• Law school clinics often provide free services

Your safety comes first. Legal protections are tools — get support to use them.''';

  String _protectiveOrdersUs() => '''A protective order is one of the most effective legal tools available to DV survivors. Here is how it works in the United States.

Types of Protective Orders

Emergency Protective Order (EPO)
Issued by police at the scene of a domestic violence incident. Lasts 3–7 days to give you time to apply for a longer-term order.

Temporary (Ex Parte) Order
Issued by a judge without the abuser present, often on the same day you apply. Typically lasts 7–21 days until a full hearing.

Final Protective Order
Issued after a court hearing (both parties present). Can last 1–5 years or permanently, depending on your state.

What a Protective Order Can Do

• Prohibit all contact (calls, texts, third-party messages, social media)
• Require the abuser to leave a shared home
• Grant you temporary custody and child support
• Prohibit the abuser from purchasing a firearm
• Cover your children, other family members, or pets (in many states)

Violations are a criminal offence — the abuser can be arrested.

How to Apply

1. Go to your local family court, domestic relations court, or courthouse self-help centre.
2. Tell the clerk you need a protective order due to domestic violence.
3. Complete the petition — describe what happened specifically.
4. A judge will review your petition, usually the same day.
5. If granted, the abuser will be served; a full hearing will be scheduled.

You do not need a lawyer to apply, though one can help. Many legal aid organisations and DV programmes provide free assistance.

Resources

• WomensLaw.org — state-specific legal information and online chat
• National DV Hotline: 1-800-799-7233
• Your local DV shelter or advocacy programme (they can accompany you to court)''';

  String _immigrantRightsUs() => '''Immigration status should never trap a survivor in an abusive relationship. US law provides specific protections for immigrant survivors.

You Have Rights Regardless of Status

Federal law prohibits immigration authorities from acting on tips provided by abusers trying to use your status against you. Threatening to report you to immigration authorities is itself a form of abuse — and one recognised by law enforcement.

VAWA Self-Petition

If you are married to (or were married to) a US citizen or lawful permanent resident who abused you, you may be eligible to file a VAWA self-petition. This allows you to apply for immigration status independently — without your abuser's knowledge or cooperation.

Who qualifies:
• Spouses (current or former) abused by a US citizen or LPR
• Children abused by a US citizen or LPR parent
• Parents of US citizens who were abused by their adult child

The U Visa

The U visa is for survivors of serious crimes — including domestic violence — who have suffered abuse and are willing to assist law enforcement. It provides:
• Temporary legal status (4 years)
• Work authorisation
• A path to a green card after 3 years

The T Visa

For survivors of human trafficking, including forced labour and sex trafficking. Provides similar protections to the U visa.

VAWA Confidentiality

USCIS is prohibited by law from disclosing information from a VAWA self-petition or U visa application to the abuser or to immigration enforcement agencies.

Getting Help

• National Immigrant Women's Advocacy Project: niwap.org
• National DV Hotline: 1-800-799-7233 (multilingual)
• Your local legal aid organisation — many have immigration specialists
• Casa de Esperanza: 651-646-5553 (for Latina survivors)

You deserve safety — your immigration status does not change that.''';

  String _findingShelterUs() => '''If you need to leave home, shelter options are available in every state. Here is how to find them quickly.

Emergency Shelter

DV shelters provide safe, confidential housing for survivors and their children — usually at no cost. Locations are kept private to protect residents.

How to Find a Shelter Now

• Call the National DV Hotline: 1-800-799-7233 (24/7, multilingual)
  They will connect you with the nearest open shelter bed.
• Text START to 88788
• Chat online at thehotline.org
• Call 211 — the social services helpline available in most US states

What to Expect at a Shelter

• Safe, private accommodation for you and your children
• Meals and basic necessities
• Counselling and case management
• Help with protective orders, benefits, and housing applications
• Children's programming
• Typically 30–90 day stays; extensions often available

Transitional Housing

After emergency shelter, transitional housing programmes provide longer-term support (6–24 months) while you rebuild your independence. They often include:
• Subsidised rent
• Life skills and employment support
• Continued case management

Other Housing Options

• VAWA housing protections: landlords cannot evict you for being a DV victim; you may be able to break a lease without penalty
• Section 8 / Housing Choice Voucher: DV survivors may qualify for priority placement
• Rapid Re-Housing: short-term rental assistance to stabilise housing quickly

Practical Tips

• Take important documents with you: ID, birth certificates, Social Security cards, financial records
• Most shelters accept pets or can connect you with pet-friendly options
• You can enter shelter even if you are not ready to leave permanently — shelters support whatever decision you make

Shelter is a bridge, not a destination. You will have support to plan your next steps.''';

  String _safetyTechUs() => '''Technology can be used to monitor, control, and stalk survivors. Knowing the risks — and how to protect yourself — is part of safety planning.

How Abusers Use Technology

Phones
• Spyware / stalkerware apps installed without your knowledge
• Monitoring call logs, texts, and location via shared accounts
• Reading messages through iCloud or Google account access

Smart Home Devices
• Smart speakers (Alexa, Google Home) can record conversations
• Smart locks, cameras, and thermostats may be controlled remotely
• "Family tracking" apps installed on your device

Accounts
• Shared email or social media login credentials
• Tracking location via Apple Find My or Google Family Sharing
• Viewing your banking or phone records

Vehicles
• AirTags or GPS trackers hidden in your car
• Reviewing vehicle location history through a connected app

Steps to Protect Yourself

Devices
• Use a device the abuser does not know about (library computer, a friend's phone)
• Change all passwords from a safe device on a network the abuser cannot access
• Review and remove apps you did not install

Accounts
• Enable two-factor authentication with a new number/email
• Revoke access from shared accounts (Apple, Google, Amazon)
• Check which devices are logged into your accounts

Location
• Disable location sharing
• Check for AirTags: on iPhone — pair detection is built in. On Android — use the AirTag Detector app
• Have a trusted mechanic check your vehicle if you suspect a tracker

Getting Help

• Safety Net Project (NNEDV): techsafety.org — detailed guides on every platform
• National DV Hotline: 1-800-799-7233 (ask for a tech safety specialist)

Always clear your browser history after researching your safety.''';

  String _financialGh() => '''Economic abuse is one of the most common forms of domestic violence in Ghana — and one of the biggest barriers to leaving. Here is how to start building independence.

Understanding Economic Abuse

Economic abuse includes: controlling all household money, preventing you from working, taking your wages, creating debt in your name, or denying you knowledge of the family's finances.

First Steps

Know what assets exist
If it is safe to do so, find out what accounts, property, or savings exist. Note account numbers, property deeds, and vehicle registration.

Open your own account
If you do not have a personal bank account, open one — separately from any joint accounts. Many banks allow this with a minimal opening balance.

Keep copies of important documents
ID card, passport, birth certificate, marriage certificate, educational certificates. Store copies with someone you trust outside the home.

Building Income

• If you are unemployed or underemployed, look into government training programmes through the Department of Social Welfare and the NVTI (National Vocational Training Institute).
• Women's enterprise funds and microfinance institutions (e.g., Sinapi Aba Trust) provide small business loans.
• The Ghana Enterprise Agency supports small business development.

Accessing Benefits

If you leave home and have children, the Department of Social Welfare can provide emergency assistance and help connect you to LEAP (Livelihood Empowerment Against Poverty) cash transfers if you qualify.

Legal Entitlements

Under Ghana law, you may be entitled to:
• Division of marital property upon separation or divorce
• Maintenance payments from your spouse
• A share of any jointly owned land or home

Contact FIDA Ghana (030 221 1681) for free legal advice on property and financial rights.''';

  String _financialUs() => '''Economic abuse is one of the most common forms of domestic violence — and one of the most powerful reasons survivors feel they cannot leave. Here is how to start building independence.

Understanding Economic Abuse

Economic abuse includes: controlling all household money, preventing you from working, sabotaging your employment, creating debt in your name, or withholding financial information.

Immediate Steps

Safety first: Do not access accounts or take financial steps that the abuser will notice if it could put you in danger. Plan from a safe device on a network they cannot monitor.

Document what exists
Note: bank account numbers, retirement accounts, property deeds, vehicle titles, tax returns. Photograph or copy documents if it is safe to do so.

Open a separate account
Many banks allow you to open an account with a low minimum balance. Use a new email address and a mailing address the abuser does not know (a shelter, a trusted friend, or a PO Box).

Access your credit report
Review your credit at annualcreditreport.com. Look for accounts you did not open — economic abuse often includes taking out debt in your name.

Financial Assistance Available to Survivors

• TANF (Temporary Assistance for Needy Families): Cash assistance for families with children
• SNAP (Food Stamps): Food assistance
• WIC: Nutrition support for pregnant women and young children
• Emergency rental assistance: Available through local community action agencies and 211
• Victims Compensation Fund: Your state may reimburse expenses related to the abuse (medical, relocation, counselling)

Employment Support

• The National DV Hotline can connect you with financial empowerment programmes in your area
• Dress for Success and similar organisations provide professional clothing and job coaching
• Many DV shelters offer job placement assistance

Legal Financial Rights

You may be entitled to:
• Division of marital assets upon divorce
• Child support and spousal maintenance
• VAWA housing protections (cannot be evicted due to DV status)

A legal aid attorney can help you understand your specific entitlements.''';

  // ─── Related articles ────────────────────────────────────────────────────

  List<Map<String, String>> _related(String id) {
    final allRelated = {
      'understanding_dv': [
        {'id': 'cycle_of_abuse', 'title': 'Understanding the Cycle of Abuse', 'category': 'Education'},
        {'id': 'safety_plan', 'title': 'Creating Your Safety Plan', 'category': 'Safety'},
        if (_isUs) {'id': 'legal_rights_us', 'title': 'Your Legal Rights — VAWA & State Laws', 'category': 'Legal'}
        else {'id': 'legal_rights_gh', 'title': 'Your Legal Rights — DV Act 732', 'category': 'Legal'},
      ],
      'safety_plan': [
        {'id': 'understanding_dv', 'title': 'Understanding Domestic Violence', 'category': 'Education'},
        if (_isUs) {'id': 'safety_tech_us', 'title': 'Technology Safety & Digital Privacy', 'category': 'Safety'}
        else {'id': 'dovvsu_guide', 'title': 'How DOVVSU Can Help You', 'category': 'Resources'},
        {'id': 'self_care_crisis', 'title': 'Self-Care During Crisis', 'category': 'Wellness'},
      ],
      'legal_rights_gh': [
        {'id': 'dovvsu_guide', 'title': 'How DOVVSU Can Help You', 'category': 'Resources'},
        {'id': 'ark_foundation', 'title': 'Shelter & Support in Ghana', 'category': 'Resources'},
        {'id': 'customary_law_gh', 'title': 'Traditional Practices & Your Rights', 'category': 'Legal'},
      ],
      'legal_rights_us': [
        {'id': 'protective_orders_us', 'title': 'Protective Orders & Restraining Orders', 'category': 'Legal'},
        {'id': 'immigrant_rights_us', 'title': 'Immigrant Survivor Rights', 'category': 'Legal'},
        {'id': 'finding_shelter_us', 'title': 'Finding Shelter & Housing Support', 'category': 'Resources'},
      ],
    };

    return (allRelated[id] ?? [
      {'id': 'safety_plan', 'title': 'Creating Your Safety Plan', 'category': 'Safety'},
      {'id': 'self_care_crisis', 'title': 'Self-Care During Crisis', 'category': 'Wellness'},
      {'id': 'healing_trauma', 'title': 'Healing from Trauma', 'category': 'Wellness'},
    ]).take(3).toList().cast<Map<String, String>>();
  }
}
