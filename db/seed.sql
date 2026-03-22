--
-- PostgreSQL database dump
--

\restrict qHr4AALZFeThh6f5qEiC2Chx4n7b30w95OHPNSWfoyNK4Ivl2YmPOWuLJDpzCTO

-- Dumped from database version 16.11
-- Dumped by pg_dump version 16.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.alerts (
    id integer NOT NULL,
    event_id integer,
    camera_id character varying(20),
    title character varying(200) NOT NULL,
    severity character varying(20) DEFAULT 'medium'::character varying,
    status character varying(20) DEFAULT 'open'::character varying,
    acknowledged_at timestamp with time zone,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.alerts OWNER TO ssg;

--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.alerts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alerts_id_seq OWNER TO ssg;

--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: analysis_jobs; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.analysis_jobs (
    id integer NOT NULL,
    camera_id character varying(20),
    video_path character varying(500) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    model character varying(100) DEFAULT 'Qwen/Qwen2.5-VL-3B-Instruct'::character varying,
    interval_sec numeric(4,1) DEFAULT 3.0,
    total_frames integer DEFAULT 0,
    processed_frames integer DEFAULT 0,
    error_msg text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    process_id integer,
    sop_id integer,
    rule_set_id integer
);


ALTER TABLE public.analysis_jobs OWNER TO ssg;

--
-- Name: analysis_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.analysis_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.analysis_jobs_id_seq OWNER TO ssg;

--
-- Name: analysis_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.analysis_jobs_id_seq OWNED BY public.analysis_jobs.id;


--
-- Name: cameras; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.cameras (
    id character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    zone character varying(100),
    location character varying(200),
    status character varying(20) DEFAULT 'online'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    process_id integer,
    sop_id integer,
    process character varying(150),
    station character varying(150),
    fps integer DEFAULT 15,
    video_src character varying(500),
    archived boolean DEFAULT false,
    archived_at timestamp with time zone,
    ai_summary text
);


ALTER TABLE public.cameras OWNER TO ssg;

--
-- Name: events; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.events (
    id integer NOT NULL,
    camera_id character varying(20),
    event_type character varying(50) NOT NULL,
    severity character varying(20) DEFAULT 'medium'::character varying,
    description text,
    confidence numeric(5,2),
    metadata jsonb,
    occurred_at timestamp with time zone DEFAULT now(),
    video_offset_seconds double precision,
    event_type_label text
);


ALTER TABLE public.events OWNER TO ssg;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.events_id_seq OWNER TO ssg;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: frame_results; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.frame_results (
    id integer NOT NULL,
    job_id integer,
    camera_id character varying(20),
    event_id integer,
    frame_idx integer NOT NULL,
    timestamp_sec numeric(8,2),
    timestamp_str character varying(20),
    description text,
    safety_status character varying(20),
    frame_path character varying(500),
    latency_ms integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.frame_results OWNER TO ssg;

--
-- Name: frame_results_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.frame_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.frame_results_id_seq OWNER TO ssg;

--
-- Name: frame_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.frame_results_id_seq OWNED BY public.frame_results.id;


--
-- Name: media_files; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.media_files (
    id integer NOT NULL,
    event_id integer,
    camera_id character varying(20),
    file_type character varying(10) NOT NULL,
    filename character varying(300) NOT NULL,
    filepath character varying(500) NOT NULL,
    size_bytes bigint,
    mime_type character varying(80),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.media_files OWNER TO ssg;

--
-- Name: media_files_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.media_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.media_files_id_seq OWNER TO ssg;

--
-- Name: media_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.media_files_id_seq OWNED BY public.media_files.id;


--
-- Name: processes; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.processes (
    id integer NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(200) NOT NULL,
    name_th character varying(200),
    description text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.processes OWNER TO ssg;

--
-- Name: processes_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.processes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.processes_id_seq OWNER TO ssg;

--
-- Name: processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.processes_id_seq OWNED BY public.processes.id;


--
-- Name: prompts; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.prompts (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    category character varying(50),
    content text NOT NULL,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    code character varying(20),
    type character varying(50) DEFAULT 'CUSTOM'::character varying,
    type_color character varying(20) DEFAULT '#1d6ef5'::character varying,
    is_system boolean DEFAULT false,
    is_pinned boolean DEFAULT false,
    updated_at timestamp with time zone,
    last_test_output text,
    last_test_json jsonb
);


ALTER TABLE public.prompts OWNER TO ssg;

--
-- Name: prompts_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.prompts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prompts_id_seq OWNER TO ssg;

--
-- Name: prompts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.prompts_id_seq OWNED BY public.prompts.id;


--
-- Name: safety_rule_items; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.safety_rule_items (
    id integer NOT NULL,
    rule_set_id integer,
    category character varying(50) NOT NULL,
    rule_text text NOT NULL,
    rule_text_th text,
    severity character varying(20) DEFAULT 'medium'::character varying,
    is_prohibited boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    sub_section character varying(50)
);


ALTER TABLE public.safety_rule_items OWNER TO ssg;

--
-- Name: safety_rule_items_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.safety_rule_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.safety_rule_items_id_seq OWNER TO ssg;

--
-- Name: safety_rule_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.safety_rule_items_id_seq OWNED BY public.safety_rule_items.id;


--
-- Name: safety_rule_sets; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.safety_rule_sets (
    id integer NOT NULL,
    process_id integer,
    title character varying(200) NOT NULL,
    title_th character varying(200),
    version character varying(10) DEFAULT '1.0'::character varying,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.safety_rule_sets OWNER TO ssg;

--
-- Name: safety_rule_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.safety_rule_sets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.safety_rule_sets_id_seq OWNER TO ssg;

--
-- Name: safety_rule_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.safety_rule_sets_id_seq OWNED BY public.safety_rule_sets.id;


--
-- Name: safety_rules; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.safety_rules (
    id integer NOT NULL,
    category character varying(50) NOT NULL,
    description text NOT NULL,
    severity character varying(20) DEFAULT 'medium'::character varying,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.safety_rules OWNER TO ssg;

--
-- Name: safety_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.safety_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.safety_rules_id_seq OWNER TO ssg;

--
-- Name: safety_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.safety_rules_id_seq OWNED BY public.safety_rules.id;


--
-- Name: sop_steps; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.sop_steps (
    id integer NOT NULL,
    sop_id integer,
    step_no integer NOT NULL,
    description text NOT NULL,
    title character varying(200),
    title_th character varying(200),
    is_critical boolean DEFAULT false
);


ALTER TABLE public.sop_steps OWNER TO ssg;

--
-- Name: sop_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.sop_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sop_steps_id_seq OWNER TO ssg;

--
-- Name: sop_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.sop_steps_id_seq OWNED BY public.sop_steps.id;


--
-- Name: sops; Type: TABLE; Schema: public; Owner: ssg
--

CREATE TABLE public.sops (
    id integer NOT NULL,
    code character varying(30) NOT NULL,
    title character varying(200) NOT NULL,
    category character varying(50),
    status character varying(20) DEFAULT 'active'::character varying,
    version character varying(10) DEFAULT '1.0'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    process_id integer,
    title_th character varying(200),
    purpose text,
    responsible text,
    equipment text,
    kpi text,
    active boolean DEFAULT true,
    safety_rules text
);


ALTER TABLE public.sops OWNER TO ssg;

--
-- Name: sops_id_seq; Type: SEQUENCE; Schema: public; Owner: ssg
--

CREATE SEQUENCE public.sops_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sops_id_seq OWNER TO ssg;

--
-- Name: sops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ssg
--

ALTER SEQUENCE public.sops_id_seq OWNED BY public.sops.id;


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: analysis_jobs id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.analysis_jobs ALTER COLUMN id SET DEFAULT nextval('public.analysis_jobs_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: frame_results id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.frame_results ALTER COLUMN id SET DEFAULT nextval('public.frame_results_id_seq'::regclass);


--
-- Name: media_files id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.media_files ALTER COLUMN id SET DEFAULT nextval('public.media_files_id_seq'::regclass);


--
-- Name: processes id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.processes ALTER COLUMN id SET DEFAULT nextval('public.processes_id_seq'::regclass);


--
-- Name: prompts id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.prompts ALTER COLUMN id SET DEFAULT nextval('public.prompts_id_seq'::regclass);


--
-- Name: safety_rule_items id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.safety_rule_items ALTER COLUMN id SET DEFAULT nextval('public.safety_rule_items_id_seq'::regclass);


--
-- Name: safety_rule_sets id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.safety_rule_sets ALTER COLUMN id SET DEFAULT nextval('public.safety_rule_sets_id_seq'::regclass);


--
-- Name: safety_rules id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.safety_rules ALTER COLUMN id SET DEFAULT nextval('public.safety_rules_id_seq'::regclass);


--
-- Name: sop_steps id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.sop_steps ALTER COLUMN id SET DEFAULT nextval('public.sop_steps_id_seq'::regclass);


--
-- Name: sops id; Type: DEFAULT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.sops ALTER COLUMN id SET DEFAULT nextval('public.sops_id_seq'::regclass);


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.alerts (id, event_id, camera_id, title, severity, status, acknowledged_at, resolved_at, created_at) FROM stdin;
1	23	CAM-A04	WARNING: In the image, there are three workers present:\n\n1. **Workers Visible and Their P	high	open	\N	\N	2026-03-21 00:03:50.404438+00
2	25	CAM-A04	WARNING: ### Scene Description\n\n**1. Workers Visible and Their PPE:**\n- **Workers:** Ther	high	open	\N	\N	2026-03-21 00:03:50.404438+00
3	29	CAM-A04	WARNING: In the image, there is a worker using a broom to sweep gravel off a concrete flo	high	open	\N	\N	2026-03-21 00:03:50.404438+00
4	70	CAM-A04	WARNING: ### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers*	high	open	\N	\N	2026-03-21 00:24:43.951632+00
5	74	CAM-A04	DANGER: ### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Worker 1	critical	open	\N	\N	2026-03-21 00:24:43.951632+00
6	75	CAM-A04	WARNING: ### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers*	high	open	\N	\N	2026-03-21 00:24:43.951632+00
7	76	CAM-A04	WARNING: ### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers*	high	open	\N	\N	2026-03-21 00:24:43.951632+00
8	78	CAM-A04	WARNING: ### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Worker 1	high	open	\N	\N	2026-03-21 00:24:43.951632+00
\.


--
-- Data for Name: analysis_jobs; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.analysis_jobs (id, camera_id, video_path, status, model, interval_sec, total_frames, processed_frames, error_msg, started_at, finished_at, created_at, process_id, sop_id, rule_set_id) FROM stdin;
10	CAM-A01	/app/media/videos/13ef5af3fdb841c5aa3aee201116c821.mp4	done_no_ai	Qwen/Qwen2.5-VL-3B-Instruct	3.0	19	19	\N	2026-03-21 00:41:35.972266+00	2026-03-21 00:41:52.059324+00	2026-03-21 00:41:35.966018+00	\N	\N	\N
1	CAM-A02	/app/media/videos/19e8bf701b0945bcb4753d7db0ae4625.mp4	failed	Qwen/Qwen2.5-VL-3B-Instruct	3.0	0	0	No module named 'torch'	2026-03-20 23:57:03.559986+00	2026-03-20 23:57:03.593816+00	2026-03-20 23:57:03.240877+00	\N	\N	\N
2	CAM-A02	/app/media/videos/477921707c3642a68afcda7516a10bf8.mp4	failed	Qwen/Qwen2.5-VL-3B-Instruct	1.0	0	0	No module named 'torch'	2026-03-20 23:57:27.34466+00	2026-03-20 23:57:27.348436+00	2026-03-20 23:57:27.340125+00	\N	\N	\N
5	CAM-A02	/app/media/videos/c7eec0c6d78941fbbfd3e00179cf19f3.mp4	done_no_ai	Qwen/Qwen2.5-VL-3B-Instruct	3.0	19	19	\N	2026-03-21 00:04:26.870574+00	2026-03-21 00:04:42.460617+00	2026-03-21 00:04:26.712133+00	\N	\N	\N
9	CAM-A01	/app/media/videos/c99150a52312430b92d6a095cccea6b0.mp4	done_no_ai	Qwen/Qwen2.5-VL-3B-Instruct	3.0	19	19	\N	2026-03-21 00:33:43.407421+00	2026-03-21 00:33:57.90485+00	2026-03-21 00:33:43.385563+00	\N	\N	\N
8	CAM-A01	/app/media/videos/5572ac013b5f4daeb277f67506dcb3f3.mp4	done_no_ai	Qwen/Qwen2.5-VL-3B-Instruct	3.0	19	19	\N	2026-03-21 00:25:49.061963+00	2026-03-21 00:26:05.616507+00	2026-03-21 00:25:48.784947+00	\N	\N	\N
3	CAM-A01	/app/media/videos/8dd16b06862e46c4a85d84a218632f88.mp4	done_no_ai	Qwen/Qwen2.5-VL-3B-Instruct	3.0	19	19	\N	2026-03-21 00:00:12.426313+00	2026-03-21 00:00:30.012282+00	2026-03-21 00:00:12.126807+00	\N	\N	\N
4	CAM-A04	demo_videos/sample_forklift_safety.mp4	done	Qwen/Qwen2.5-VL-3B-Instruct	3.0	10	10	\N	2026-03-21 00:03:50.402219+00	2026-03-21 00:03:50.402222+00	2026-03-21 00:03:50.404438+00	\N	\N	\N
13	CAM-A01	/app/media/videos/e61c0619a81f40579318678d73d9e9bf.mp4	done_no_ai	Qwen/Qwen2.5-VL-3B-Instruct	3.0	19	19	\N	2026-03-21 09:12:32.956147+00	2026-03-21 09:12:48.454853+00	2026-03-21 09:12:32.528483+00	1	\N	1
11	CAM-A01	/app/media/videos/e9cba898a5e44341a577c0e93148816b.mp4	done_no_ai	Qwen/Qwen2.5-VL-3B-Instruct	3.0	19	19	\N	2026-03-21 00:42:03.149843+00	2026-03-21 00:42:20.038387+00	2026-03-21 00:42:03.144098+00	\N	\N	\N
12	CAM-A01	/app/media/videos/0805bd247b5c400487dfa3e318f86245.mp4	running	Qwen/Qwen2.5-VL-3B-Instruct	3.0	0	0	\N	2026-03-21 00:46:03.184021+00	\N	2026-03-21 00:46:03.168715+00	\N	\N	\N
6	CAM-A02	/app/media/videos/1aa9d019874841c6b6160697ada57bc3.mp4	done_no_ai	Qwen/Qwen2.5-VL-3B-Instruct	3.0	19	19	\N	2026-03-21 00:07:39.788642+00	2026-03-21 00:07:54.210555+00	2026-03-21 00:07:39.782358+00	\N	\N	\N
7	CAM-A04	d:/3.KMITL_ai/projects/4_Denso Smart Factory Smart Safety/vila-safety-poc/demo_videos/การเคลื่อนย้ายม้วนวัสดุด้วย Forklift (Roll Handling).mp4	done	Qwen/Qwen2.5-VL-3B-Instruct	5.0	12	12	\N	2026-03-21 00:24:43.947545+00	2026-03-21 00:24:43.947548+00	2026-03-21 00:24:43.951632+00	\N	\N	\N
\.


--
-- Data for Name: cameras; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.cameras (id, name, zone, location, status, created_at, process_id, sop_id, process, station, fps, video_src, archived, archived_at, ai_summary) FROM stdin;
CAM-A02	Assembly Line A — Station 2	Zone A	Building 1, Floor 1	online	2026-03-20 14:37:56.107565+00	\N	\N	Zone A	Building 1, Floor 1	15	\N	t	2026-03-22 02:11:18.381844+00	\N
CAM-A01	Assembly Line A — Station 1	Zone A	Building 1, Floor 1	online	2026-03-20 14:37:56.107565+00	\N	\N	Zone A	Building 1, Floor 1	15	\N	t	2026-03-22 02:11:25.910119+00	\N
CAM-A04	Forklift Corridor C	Zone C	Building 1, Corridor	online	2026-03-20 14:37:56.107565+00	\N	\N	Zone C	Building 1, Corridor	15	\N	t	2026-03-22 02:11:29.101765+00	\N
CAM-A05	Inspection 1-2	\N	\N	online	2026-03-22 09:12:40.911847+00	2	4	Inspection and Clean the Can.	Station 1-2	15	/media/videos/69953788c36641b6b331e47888a8ecf3.mp4	f	\N	SAFETY_EVENTS_CONTEXT:\nVideo: Mock Station.mp4 | Duration: 3:39 | Date: 2026-03-22\n\nKEY_EVENTS:\n[EVT-001] timestamp=02:55 severity=CRITICAL type=NEAR_MISS\n  desc="Person B ยื่นมือขวาเข้าส่วนกลางเครื่องจักรขณะสายพานยังเดิน"\n  rule="สายพานหนีบมือ" action_required="EMERGENCY STOP + ตรวจสอบการบาดเจ็บ"\n\n[EVT-002] timestamp=01:13~02:02 severity=MEDIUM type=STEP_SKIP count=21\n  desc="Worker1 หยิบกระป๋องจากกล่อง NG วางขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"\n  sop_violated="Step 2 (visual inspection)" root_cause="กล่อง WAIT หมด [01:05]"\n\n[EVT-003] timestamp=02:59~03:38 severity=MEDIUM type=PPE_VIOLATION count=6\n  desc="Person B ถอดหมวก (02:59, 03:35) และถุงมือ (03:35) ขณะเครื่องจักรยังทำงาน"\n  rule="PPE บังคับตลอดเวลาในพื้นที่"\n\n[EVT-004] timestamp=01:39 severity=MEDIUM type=FOREIGN_OBJECT count=1\n  desc="Person B วางขวดน้ำบนโต๊ะทำงาน หลังรับจาก Person C"\n  rule="ห้ามวางของไม่เกี่ยวข้องบนพื้นที่ทำงาน"\n\n[EVT-005] timestamp=01:36~01:40 severity=LOW type=UNAUTHORIZED_ENTRY count=4\n  desc="Person C (บุคคลภายนอก) เดินเข้าพื้นที่ทำงาน ยื่นขวดน้ำให้ Person B"\n  rule="ห้ามบุคคลอื่นเข้าพื้นที่โดยไม่ได้รับอนุญาต"\n\nSTATS:\n  total_events=39 | critical=1 | medium=34 | low=4\n  ng_cans=4 | duration_sec=219 | workers=2\n\nSAMPLE_QA:\nQ: มีเหตุการณ์อะไรที่อันตรายที่สุด?\nA: EVT-001 [02:55] Critical — Person B ยื่นมือเข้าเครื่องจักรขณะสายพานเดิน\n\nQ: ทำงานข้ามขั้นตอนกี่ครั้ง?\nA: 21 ครั้ง ช่วง [01:13–02:02] (EVT-002) สาเหตุ: กล่อง WAIT หมด\n\nQ: PPE violation เกิดกี่ครั้ง?\nA: 6 ครั้ง ช่วง [02:59–03:38] (EVT-003) Person B ถอดหมวก+ถุงมือ\n\nQ: มีบุคคลภายนอกเข้ามาไหม?\nA: ใช่ [01:36–01:40] Person C เดินเข้า ส่งขวดน้ำ แล้วออก (EVT-005)
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.events (id, camera_id, event_type, severity, description, confidence, metadata, occurred_at, video_offset_seconds, event_type_label) FROM stdin;
1	CAM-A01	VLM_PENDING	medium	[Frame 0 at 0:00:00] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 0, "safety_status": "PENDING", "timestamp_str": "0:00:00"}	2026-03-21 00:00:29.456678+00	\N	\N
2	CAM-A01	VLM_PENDING	medium	[Frame 179 at 0:00:02] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 179, "safety_status": "PENDING", "timestamp_str": "0:00:02"}	2026-03-21 00:00:29.522736+00	\N	\N
3	CAM-A01	VLM_PENDING	medium	[Frame 358 at 0:00:05] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 358, "safety_status": "PENDING", "timestamp_str": "0:00:05"}	2026-03-21 00:00:29.566128+00	\N	\N
4	CAM-A01	VLM_PENDING	medium	[Frame 537 at 0:00:08] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 537, "safety_status": "PENDING", "timestamp_str": "0:00:08"}	2026-03-21 00:00:29.598327+00	\N	\N
5	CAM-A01	VLM_PENDING	medium	[Frame 716 at 0:00:11] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 716, "safety_status": "PENDING", "timestamp_str": "0:00:11"}	2026-03-21 00:00:29.625971+00	\N	\N
6	CAM-A01	VLM_PENDING	medium	[Frame 895 at 0:00:14] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 895, "safety_status": "PENDING", "timestamp_str": "0:00:14"}	2026-03-21 00:00:29.650445+00	\N	\N
7	CAM-A01	VLM_PENDING	medium	[Frame 1074 at 0:00:17] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 1074, "safety_status": "PENDING", "timestamp_str": "0:00:17"}	2026-03-21 00:00:29.67605+00	\N	\N
8	CAM-A01	VLM_PENDING	medium	[Frame 1253 at 0:00:20] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 1253, "safety_status": "PENDING", "timestamp_str": "0:00:20"}	2026-03-21 00:00:29.700165+00	\N	\N
9	CAM-A01	VLM_PENDING	medium	[Frame 1432 at 0:00:23] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 1432, "safety_status": "PENDING", "timestamp_str": "0:00:23"}	2026-03-21 00:00:29.724482+00	\N	\N
10	CAM-A01	VLM_PENDING	medium	[Frame 1611 at 0:00:26] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 1611, "safety_status": "PENDING", "timestamp_str": "0:00:26"}	2026-03-21 00:00:29.749089+00	\N	\N
11	CAM-A01	VLM_PENDING	medium	[Frame 1790 at 0:00:29] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 1790, "safety_status": "PENDING", "timestamp_str": "0:00:29"}	2026-03-21 00:00:29.774923+00	\N	\N
12	CAM-A01	VLM_PENDING	medium	[Frame 1969 at 0:00:32] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 1969, "safety_status": "PENDING", "timestamp_str": "0:00:32"}	2026-03-21 00:00:29.800329+00	\N	\N
13	CAM-A01	VLM_PENDING	medium	[Frame 2148 at 0:00:35] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 2148, "safety_status": "PENDING", "timestamp_str": "0:00:35"}	2026-03-21 00:00:29.826742+00	\N	\N
14	CAM-A01	VLM_PENDING	medium	[Frame 2327 at 0:00:38] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 2327, "safety_status": "PENDING", "timestamp_str": "0:00:38"}	2026-03-21 00:00:29.853924+00	\N	\N
15	CAM-A01	VLM_PENDING	medium	[Frame 2506 at 0:00:41] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 2506, "safety_status": "PENDING", "timestamp_str": "0:00:41"}	2026-03-21 00:00:29.880934+00	\N	\N
16	CAM-A01	VLM_PENDING	medium	[Frame 2685 at 0:00:44] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 2685, "safety_status": "PENDING", "timestamp_str": "0:00:44"}	2026-03-21 00:00:29.907847+00	\N	\N
17	CAM-A01	VLM_PENDING	medium	[Frame 2864 at 0:00:47] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 2864, "safety_status": "PENDING", "timestamp_str": "0:00:47"}	2026-03-21 00:00:29.934901+00	\N	\N
18	CAM-A01	VLM_PENDING	medium	[Frame 3043 at 0:00:50] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 3043, "safety_status": "PENDING", "timestamp_str": "0:00:50"}	2026-03-21 00:00:29.960423+00	\N	\N
19	CAM-A01	VLM_PENDING	medium	[Frame 3222 at 0:00:53] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 3, "frame_idx": 3222, "safety_status": "PENDING", "timestamp_str": "0:00:53"}	2026-03-21 00:00:29.988231+00	\N	\N
20	CAM-A04	VLM_SAFE	low	I'm sorry, but I cannot provide a detailed description of a scene without being able to see it. Please provide me with more information about the scene you would like me to describe.	0.90	{"job_id": 4, "frame_idx": 0, "latency_ms": 4004, "safety_status": "SAFE", "timestamp_str": "0:00:00"}	2026-03-21 00:03:50.404438+00	\N	\N
21	CAM-A04	VLM_SAFE	low	In the image provided, there is a black-and-white photograph of a factory floor with several workers visible. Here is a detailed description:\n\n1. **Workers Visible and Their PPE**:\n   - There are multiple workers on the factory floor. They are wearing standard factory attire, which typically includes:\n     - **Helmet**: The workers are wearing hard hats to protect their heads from potential impacts.\n     - **Vest**: Many workers are wearing reflective vests to enhance visibility.\n     - **Gloves	0.90	{"job_id": 4, "frame_idx": 71, "latency_ms": 17416, "safety_status": "SAFE", "timestamp_str": "0:00:02"}	2026-03-21 00:03:50.404438+00	\N	\N
22	CAM-A04	VLM_SAFE	low	In the image, there is a worker operating a yellow forklift near stacks of wooden pallets and green shipping containers. The worker is wearing a black shirt, blue jeans, and a yellow hard hat with a face shield. They are also wearing gloves and sturdy work boots.\n\nThe equipment and machinery present include the yellow forklift, which is being used to move the pallets. There are no other pieces of machinery visible in the image.\n\nThere are no immediate safety hazards or violations observed in the	0.90	{"job_id": 4, "frame_idx": 142, "latency_ms": 8238, "safety_status": "SAFE", "timestamp_str": "0:00:05"}	2026-03-21 00:03:50.404438+00	\N	\N
23	CAM-A04	VLM_WARNING	high	In the image, there are three workers present:\n\n1. **Workers Visible and Their PPE**:\n   - The worker on the left is wearing a black shirt, blue jeans, and a high-visibility orange vest. He is sitting on the ground with his hands clasped together.\n   - The worker in the middle is wearing a yellow safety vest, blue jeans, and brown work boots. They appear to be kneeling or crouching down.\n   - The worker on the right is wearing a black shirt, blue jeans, and black work boots. He is standing next 	0.90	{"job_id": 4, "frame_idx": 213, "latency_ms": 18081, "safety_status": "WARNING", "timestamp_str": "0:00:08"}	2026-03-21 00:03:50.404438+00	\N	\N
44	CAM-A02	VLM_PENDING	medium	[Frame 2506 at 0:00:41] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 2506, "safety_status": "PENDING", "timestamp_str": "0:00:41"}	2026-03-21 00:04:42.296473+00	\N	\N
99	CAM-A01	VLM_PENDING	medium	[Frame 0 at 0:00:00] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 0, "safety_status": "PENDING", "timestamp_str": "0:00:00"}	2026-03-21 00:33:57.396151+00	\N	\N
24	CAM-A04	VLM_SAFE	low	**Scene Description:**\n\nThe scene depicts a forklift moving along a concrete floor outside a large industrial building. The forklift is yellow with black accents and is being operated by a worker who is wearing a dark-colored shirt, sunglasses, and a helmet. The worker is also wearing gloves and boots.\n\n**Workers Visible and Their PPE:**\n- **Worker:** The worker operating the forklift is wearing a helmet, a high-visibility vest, gloves, and boots.\n- **Safety Vest:** The worker is wearing a high-	0.90	{"job_id": 4, "frame_idx": 284, "latency_ms": 18018, "safety_status": "SAFE", "timestamp_str": "0:00:11"}	2026-03-21 00:03:50.404438+00	\N	\N
25	CAM-A04	VLM_WARNING	high	### Scene Description\n\n**1. Workers Visible and Their PPE:**\n- **Workers:** There is one worker visible in the image.\n- **PPE:** The worker is wearing a helmet, a high-visibility vest, gloves, and work boots.\n\n**2. Equipment and Machinery:**\n- **Forklift:** A yellow Hyster forklift is prominently featured in the foreground. It appears to be parked or moving slowly on a concrete surface.\n- **Safety Gear:** The forklift has a blue safety guard attached to its front end, which likely serves as a pr	0.90	{"job_id": 4, "frame_idx": 355, "latency_ms": 17502, "safety_status": "WARNING", "timestamp_str": "0:00:14"}	2026-03-21 00:03:50.404438+00	\N	\N
26	CAM-A04	VLM_SAFE	low	### Scene Description:\n\n**1. Workers Visible and Their PPE:**\n- There is one worker visible in the image.\n- The worker is wearing a yellow safety vest and a helmet.\n- The worker is also wearing gloves and boots.\n\n**2. Equipment and Machinery:**\n- There is a forklift parked near the building.\n- A conveyor belt system is visible, running horizontally across the image.\n- The conveyor belt appears to be in operation, with materials moving along it.\n\n**3. Safety Hazards or Violations:**\n- **Safety Ve	0.90	{"job_id": 4, "frame_idx": 426, "latency_ms": 16351, "safety_status": "SAFE", "timestamp_str": "0:00:17"}	2026-03-21 00:03:50.404438+00	\N	\N
27	CAM-A04	VLM_SAFE	low	### Scene Description:\n\n**1. Workers Visible and Their PPE:**\n- There are two workers visible in the image.\n  - The worker on the left is wearing a yellow hard hat, a high-visibility vest, gloves, and work boots.\n  - The worker on the right is also wearing a yellow hard hat, a high-visibility vest, gloves, and work boots.\n\n**2. Equipment and Machinery:**\n- A green forklift is parked near the workers.\n- There is a conveyor belt running horizontally along the right side of the image.\n- The conveyo	0.90	{"job_id": 4, "frame_idx": 497, "latency_ms": 16953, "safety_status": "SAFE", "timestamp_str": "0:00:20"}	2026-03-21 00:03:50.404438+00	\N	\N
28	CAM-A04	VLM_SAFE	low	### Scene Description\n\n**1. Workers Visible and Their PPE:**\n- **Worker 1:** \n  - Wearing a yellow safety vest with reflective stripes.\n  - Wearing blue jeans.\n  - Wearing black work boots.\n  - Holding a broom.\n\n- **Worker 2:**\n  - Wearing a yellow safety vest with reflective stripes.\n  - Wearing blue jeans.\n  - Wearing black work boots.\n  - Holding a dustpan.\n\n**2. Equipment and Machinery:**\n- The warehouse is spacious with concrete flooring.\n- There are stacks of white bags on the left side of	0.90	{"job_id": 4, "frame_idx": 568, "latency_ms": 17124, "safety_status": "SAFE", "timestamp_str": "0:00:23"}	2026-03-21 00:03:50.404438+00	\N	\N
29	CAM-A04	VLM_WARNING	high	In the image, there is a worker using a broom to sweep gravel off a concrete floor. The worker is wearing work boots and jeans, but no other PPE such as a helmet, vest, gloves, or safety shoes is visible.\n\nThere are no other workers or equipment visible in the image.\n\nThe safety hazard in this scene is the lack of proper PPE, specifically gloves and safety shoes. This could lead to injuries if the worker slips on the gravel or if they accidentally step on the gravel while sweeping.\n\nOverall, the	0.90	{"job_id": 4, "frame_idx": 639, "latency_ms": 7091, "safety_status": "WARNING", "timestamp_str": "0:00:26"}	2026-03-21 00:03:50.404438+00	\N	\N
30	CAM-A02	VLM_PENDING	medium	[Frame 0 at 0:00:00] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 0, "safety_status": "PENDING", "timestamp_str": "0:00:00"}	2026-03-21 00:04:41.587916+00	\N	\N
31	CAM-A02	VLM_PENDING	medium	[Frame 179 at 0:00:02] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 179, "safety_status": "PENDING", "timestamp_str": "0:00:02"}	2026-03-21 00:04:41.648357+00	\N	\N
32	CAM-A02	VLM_PENDING	medium	[Frame 358 at 0:00:05] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 358, "safety_status": "PENDING", "timestamp_str": "0:00:05"}	2026-03-21 00:04:41.697583+00	\N	\N
33	CAM-A02	VLM_PENDING	medium	[Frame 537 at 0:00:08] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 537, "safety_status": "PENDING", "timestamp_str": "0:00:08"}	2026-03-21 00:04:41.732563+00	\N	\N
34	CAM-A02	VLM_PENDING	medium	[Frame 716 at 0:00:11] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 716, "safety_status": "PENDING", "timestamp_str": "0:00:11"}	2026-03-21 00:04:41.758091+00	\N	\N
35	CAM-A02	VLM_PENDING	medium	[Frame 895 at 0:00:14] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 895, "safety_status": "PENDING", "timestamp_str": "0:00:14"}	2026-03-21 00:04:41.801866+00	\N	\N
36	CAM-A02	VLM_PENDING	medium	[Frame 1074 at 0:00:17] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 1074, "safety_status": "PENDING", "timestamp_str": "0:00:17"}	2026-03-21 00:04:41.829386+00	\N	\N
37	CAM-A02	VLM_PENDING	medium	[Frame 1253 at 0:00:20] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 1253, "safety_status": "PENDING", "timestamp_str": "0:00:20"}	2026-03-21 00:04:41.865439+00	\N	\N
38	CAM-A02	VLM_PENDING	medium	[Frame 1432 at 0:00:23] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 1432, "safety_status": "PENDING", "timestamp_str": "0:00:23"}	2026-03-21 00:04:41.924169+00	\N	\N
39	CAM-A02	VLM_PENDING	medium	[Frame 1611 at 0:00:26] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 1611, "safety_status": "PENDING", "timestamp_str": "0:00:26"}	2026-03-21 00:04:42.002911+00	\N	\N
40	CAM-A02	VLM_PENDING	medium	[Frame 1790 at 0:00:29] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 1790, "safety_status": "PENDING", "timestamp_str": "0:00:29"}	2026-03-21 00:04:42.038423+00	\N	\N
41	CAM-A02	VLM_PENDING	medium	[Frame 1969 at 0:00:32] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 1969, "safety_status": "PENDING", "timestamp_str": "0:00:32"}	2026-03-21 00:04:42.080909+00	\N	\N
42	CAM-A02	VLM_PENDING	medium	[Frame 2148 at 0:00:35] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 2148, "safety_status": "PENDING", "timestamp_str": "0:00:35"}	2026-03-21 00:04:42.169185+00	\N	\N
43	CAM-A02	VLM_PENDING	medium	[Frame 2327 at 0:00:38] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 2327, "safety_status": "PENDING", "timestamp_str": "0:00:38"}	2026-03-21 00:04:42.229497+00	\N	\N
45	CAM-A02	VLM_PENDING	medium	[Frame 2685 at 0:00:44] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 2685, "safety_status": "PENDING", "timestamp_str": "0:00:44"}	2026-03-21 00:04:42.334802+00	\N	\N
47	CAM-A02	VLM_PENDING	medium	[Frame 3043 at 0:00:50] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 3043, "safety_status": "PENDING", "timestamp_str": "0:00:50"}	2026-03-21 00:04:42.395472+00	\N	\N
49	CAM-A02	VLM_PENDING	medium	[Frame 0 at 0:00:00] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 0, "safety_status": "PENDING", "timestamp_str": "0:00:00"}	2026-03-21 00:07:53.684001+00	\N	\N
51	CAM-A02	VLM_PENDING	medium	[Frame 358 at 0:00:05] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 358, "safety_status": "PENDING", "timestamp_str": "0:00:05"}	2026-03-21 00:07:53.747515+00	\N	\N
53	CAM-A02	VLM_PENDING	medium	[Frame 716 at 0:00:11] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 716, "safety_status": "PENDING", "timestamp_str": "0:00:11"}	2026-03-21 00:07:53.804059+00	\N	\N
55	CAM-A02	VLM_PENDING	medium	[Frame 1074 at 0:00:17] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 1074, "safety_status": "PENDING", "timestamp_str": "0:00:17"}	2026-03-21 00:07:53.860591+00	\N	\N
57	CAM-A02	VLM_PENDING	medium	[Frame 1432 at 0:00:23] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 1432, "safety_status": "PENDING", "timestamp_str": "0:00:23"}	2026-03-21 00:07:53.913177+00	\N	\N
59	CAM-A02	VLM_PENDING	medium	[Frame 1790 at 0:00:29] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 1790, "safety_status": "PENDING", "timestamp_str": "0:00:29"}	2026-03-21 00:07:53.96681+00	\N	\N
61	CAM-A02	VLM_PENDING	medium	[Frame 2148 at 0:00:35] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 2148, "safety_status": "PENDING", "timestamp_str": "0:00:35"}	2026-03-21 00:07:54.02381+00	\N	\N
63	CAM-A02	VLM_PENDING	medium	[Frame 2506 at 0:00:41] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 2506, "safety_status": "PENDING", "timestamp_str": "0:00:41"}	2026-03-21 00:07:54.076532+00	\N	\N
65	CAM-A02	VLM_PENDING	medium	[Frame 2864 at 0:00:47] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 2864, "safety_status": "PENDING", "timestamp_str": "0:00:47"}	2026-03-21 00:07:54.12948+00	\N	\N
67	CAM-A02	VLM_PENDING	medium	[Frame 3222 at 0:00:53] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 3222, "safety_status": "PENDING", "timestamp_str": "0:00:53"}	2026-03-21 00:07:54.183148+00	\N	\N
46	CAM-A02	VLM_PENDING	medium	[Frame 2864 at 0:00:47] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 2864, "safety_status": "PENDING", "timestamp_str": "0:00:47"}	2026-03-21 00:04:42.364449+00	\N	\N
48	CAM-A02	VLM_PENDING	medium	[Frame 3222 at 0:00:53] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 5, "frame_idx": 3222, "safety_status": "PENDING", "timestamp_str": "0:00:53"}	2026-03-21 00:04:42.431597+00	\N	\N
50	CAM-A02	VLM_PENDING	medium	[Frame 179 at 0:00:02] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 179, "safety_status": "PENDING", "timestamp_str": "0:00:02"}	2026-03-21 00:07:53.711545+00	\N	\N
52	CAM-A02	VLM_PENDING	medium	[Frame 537 at 0:00:08] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 537, "safety_status": "PENDING", "timestamp_str": "0:00:08"}	2026-03-21 00:07:53.777476+00	\N	\N
54	CAM-A02	VLM_PENDING	medium	[Frame 895 at 0:00:14] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 895, "safety_status": "PENDING", "timestamp_str": "0:00:14"}	2026-03-21 00:07:53.833961+00	\N	\N
56	CAM-A02	VLM_PENDING	medium	[Frame 1253 at 0:00:20] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 1253, "safety_status": "PENDING", "timestamp_str": "0:00:20"}	2026-03-21 00:07:53.887565+00	\N	\N
58	CAM-A02	VLM_PENDING	medium	[Frame 1611 at 0:00:26] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 1611, "safety_status": "PENDING", "timestamp_str": "0:00:26"}	2026-03-21 00:07:53.939947+00	\N	\N
60	CAM-A02	VLM_PENDING	medium	[Frame 1969 at 0:00:32] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 1969, "safety_status": "PENDING", "timestamp_str": "0:00:32"}	2026-03-21 00:07:53.995596+00	\N	\N
62	CAM-A02	VLM_PENDING	medium	[Frame 2327 at 0:00:38] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 2327, "safety_status": "PENDING", "timestamp_str": "0:00:38"}	2026-03-21 00:07:54.050614+00	\N	\N
64	CAM-A02	VLM_PENDING	medium	[Frame 2685 at 0:00:44] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 2685, "safety_status": "PENDING", "timestamp_str": "0:00:44"}	2026-03-21 00:07:54.103295+00	\N	\N
66	CAM-A02	VLM_PENDING	medium	[Frame 3043 at 0:00:50] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 6, "frame_idx": 3043, "safety_status": "PENDING", "timestamp_str": "0:00:50"}	2026-03-21 00:07:54.156385+00	\N	\N
68	CAM-A04	VLM_SAFE	low	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Positioned near the left side of the image, wearing a white shirt, blue jeans, and a red helmet with a face mask. They are also wearing gloves and shoes.\n  - **Worker 2**: Positioned closer to the center-right of the image, wearing a pink shirt, blue jeans, and a red helmet with a face mask. They are also wearing gloves and shoes.\n\n#### 2. Equipment and	0.90	{"job_id": 7, "frame_idx": 0, "latency_ms": 21513, "safety_status": "SAFE", "timestamp_str": "0:00:00"}	2026-03-21 00:24:43.951632+00	\N	\N
69	CAM-A04	VLM_SAFE	low	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a red helmet, white shirt, blue jeans, and yellow gloves.\n  - **Worker 2**: Wearing a pink helmet, blue shirt, blue jeans, and yellow gloves.\n\n#### 2. Equipment and Machinery\n- **Forklift**: An orange forklift is parked near the center of the image, with its forks extended towards the ground.\n- **Conveyors**: Several conveyor belts are present, 	0.90	{"job_id": 7, "frame_idx": 299, "latency_ms": 19960, "safety_status": "SAFE", "timestamp_str": "0:00:04"}	2026-03-21 00:24:43.951632+00	\N	\N
70	CAM-A04	VLM_WARNING	high	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a red helmet, white shirt, black pants, and gloves.\n  - **Worker 2**: Wearing a red helmet, pink shirt, black pants, and gloves.\n\n#### 2. Equipment and Machinery\n- **Forklift**: An orange forklift is present in the center of the image, moving along the floor.\n- **Conveyors**: Several large cylindrical objects, possibly rolls of material, are ali	0.90	{"job_id": 7, "frame_idx": 598, "latency_ms": 20849, "safety_status": "WARNING", "timestamp_str": "0:00:09"}	2026-03-21 00:24:43.951632+00	\N	\N
71	CAM-A04	VLM_SAFE	low	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Positioned near the left side of the image, wearing a white shirt, red helmet, and blue jeans. They appear to be operating the forklift.\n  - **Worker 2**: Positioned near the right side of the image, wearing a pink shirt, blue jeans, and a yellow hard hat. They seem to be engaged in some activity related to the large cylindrical objects.\n\n#### 2. Equipm	0.90	{"job_id": 7, "frame_idx": 897, "latency_ms": 20201, "safety_status": "SAFE", "timestamp_str": "0:00:14"}	2026-03-21 00:24:43.951632+00	\N	\N
72	CAM-A04	VLM_SAFE	low	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a white shirt, red helmet, and blue jeans. They appear to be operating a forklift.\n  - **Worker 2**: Wearing a pink shirt and blue jeans. They are standing near the forklift, possibly overseeing the operation.\n\n#### 2. Equipment and Machinery\n- **Forklift**: The primary piece of equipment is an orange forklift with the brand name "JAC" visible o	0.90	{"job_id": 7, "frame_idx": 1196, "latency_ms": 20531, "safety_status": "SAFE", "timestamp_str": "0:00:19"}	2026-03-21 00:24:43.951632+00	\N	\N
73	CAM-A04	VLM_SAFE	low	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a red helmet, white shirt, blue jeans, and work boots.\n  - **Worker 2**: Wearing a pink shirt, blue jeans, and work boots.\n\n#### 2. Equipment and Machinery\n- **Forklift**: An orange forklift is parked near the workers. It has a red seat and is equipped with a fork lift.\n- **Conveyor Belt**: A conveyor belt is present in the background, running h	0.90	{"job_id": 7, "frame_idx": 1495, "latency_ms": 20649, "safety_status": "SAFE", "timestamp_str": "0:00:24"}	2026-03-21 00:24:43.951632+00	\N	\N
74	CAM-A04	VLM_DANGER	critical	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Worker 1**: \n  - **Position**: Near the right side of the image.\n  - **PPE**: Wearing a red helmet, white shirt, blue jeans, and gloves.\n  \n- **Worker 2**:\n  - **Position**: Near the center-left of the image.\n  - **PPE**: Wearing a red helmet, white shirt, blue jeans, and gloves.\n\n#### 2. Equipment and Machinery\n- **Forklift**: Positioned near the center of the image, with a worker operating it.\n- **Conveyor Belt**: Located 	0.90	{"job_id": 7, "frame_idx": 1794, "latency_ms": 19725, "safety_status": "DANGER", "timestamp_str": "0:00:29"}	2026-03-21 00:24:43.951632+00	\N	\N
75	CAM-A04	VLM_WARNING	high	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a red helmet, white shirt, black pants, and gloves.\n  - **Worker 2**: Wearing a red helmet, pink shirt, blue jeans, and gloves.\n\n#### 2. Equipment and Machinery\n- **Forklift**: An orange forklift is parked near the workers. It has a red seat and is equipped with a fork.\n- **Conveyors**: Several large cylindrical objects are on the ground, likely	0.90	{"job_id": 7, "frame_idx": 2093, "latency_ms": 21362, "safety_status": "WARNING", "timestamp_str": "0:00:34"}	2026-03-21 00:24:43.951632+00	\N	\N
76	CAM-A04	VLM_WARNING	high	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There is one worker visible in the image.\n- **PPE**:\n  - The worker is wearing a red helmet.\n  - The worker is also wearing a white shirt and blue jeans.\n\n#### 2. Equipment and Machinery\n- **Forklift**: A forklift is present in the image, positioned near the center of the warehouse.\n- **Conveyors**: There are several large cylindrical objects on the right side of the image, which appear to be conveyor belts or som	0.90	{"job_id": 7, "frame_idx": 2392, "latency_ms": 20329, "safety_status": "WARNING", "timestamp_str": "0:00:39"}	2026-03-21 00:24:43.951632+00	\N	\N
77	CAM-A04	VLM_SAFE	low	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Worker 1**: \n  - **Position**: Standing near the forklift.\n  - **PPE**: Red helmet, white shirt, blue jeans, and work boots.\n\n- **Worker 2**:\n  - **Position**: Walking towards the right side of the image.\n  - **PPE**: Pink shirt, blue jeans, and work boots.\n\n#### 2. Equipment and Machinery\n- **Forklift**: Orange forklift with a red operator's cab, positioned on the left side of the image.\n- **Conveyors**: Several large cylin	0.90	{"job_id": 7, "frame_idx": 2691, "latency_ms": 18570, "safety_status": "SAFE", "timestamp_str": "0:00:44"}	2026-03-21 00:24:43.951632+00	\N	\N
78	CAM-A04	VLM_WARNING	high	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Worker 1**: \n  - **Position**: Left side of the image.\n  - **Appearance**: Wearing a red helmet, orange safety vest, and gloves.\n  - **Activity**: Operating a forklift.\n\n- **Worker 2**:\n  - **Position**: Right side of the image.\n  - **Appearance**: Wearing a pink shirt, blue jeans, and no visible PPE except for a white helmet.\n  - **Activity**: Standing near the forklift.\n\n#### 2. Equipment and Machinery\n- **Forklift**: Posi	0.90	{"job_id": 7, "frame_idx": 2990, "latency_ms": 19977, "safety_status": "WARNING", "timestamp_str": "0:00:49"}	2026-03-21 00:24:43.951632+00	\N	\N
79	CAM-A04	VLM_SAFE	low	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There is one worker visible in the image.\n- **PPE**: The worker is wearing a pink shirt, blue jeans, and a red safety vest. They also have a helmet on.\n\n#### 2. Equipment and Machinery\n- **Forklift**: A forklift is parked near the left side of the image, partially visible.\n- **Conveyors**: There are several large rolls of material on the right side of the image, likely on conveyor belts.\n- **Storage**: Various sta	0.90	{"job_id": 7, "frame_idx": 3289, "latency_ms": 19446, "safety_status": "SAFE", "timestamp_str": "0:00:54"}	2026-03-21 00:24:43.951632+00	\N	\N
80	CAM-A01	VLM_PENDING	medium	[Frame 0 at 0:00:00] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 0, "safety_status": "PENDING", "timestamp_str": "0:00:00"}	2026-03-21 00:26:05.117914+00	\N	\N
81	CAM-A01	VLM_PENDING	medium	[Frame 179 at 0:00:02] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 179, "safety_status": "PENDING", "timestamp_str": "0:00:02"}	2026-03-21 00:26:05.153878+00	\N	\N
82	CAM-A01	VLM_PENDING	medium	[Frame 358 at 0:00:05] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 358, "safety_status": "PENDING", "timestamp_str": "0:00:05"}	2026-03-21 00:26:05.182872+00	\N	\N
83	CAM-A01	VLM_PENDING	medium	[Frame 537 at 0:00:08] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 537, "safety_status": "PENDING", "timestamp_str": "0:00:08"}	2026-03-21 00:26:05.208296+00	\N	\N
84	CAM-A01	VLM_PENDING	medium	[Frame 716 at 0:00:11] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 716, "safety_status": "PENDING", "timestamp_str": "0:00:11"}	2026-03-21 00:26:05.233125+00	\N	\N
85	CAM-A01	VLM_PENDING	medium	[Frame 895 at 0:00:14] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 895, "safety_status": "PENDING", "timestamp_str": "0:00:14"}	2026-03-21 00:26:05.258681+00	\N	\N
86	CAM-A01	VLM_PENDING	medium	[Frame 1074 at 0:00:17] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 1074, "safety_status": "PENDING", "timestamp_str": "0:00:17"}	2026-03-21 00:26:05.284294+00	\N	\N
87	CAM-A01	VLM_PENDING	medium	[Frame 1253 at 0:00:20] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 1253, "safety_status": "PENDING", "timestamp_str": "0:00:20"}	2026-03-21 00:26:05.310273+00	\N	\N
88	CAM-A01	VLM_PENDING	medium	[Frame 1432 at 0:00:23] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 1432, "safety_status": "PENDING", "timestamp_str": "0:00:23"}	2026-03-21 00:26:05.335323+00	\N	\N
89	CAM-A01	VLM_PENDING	medium	[Frame 1611 at 0:00:26] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 1611, "safety_status": "PENDING", "timestamp_str": "0:00:26"}	2026-03-21 00:26:05.359515+00	\N	\N
90	CAM-A01	VLM_PENDING	medium	[Frame 1790 at 0:00:29] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 1790, "safety_status": "PENDING", "timestamp_str": "0:00:29"}	2026-03-21 00:26:05.386377+00	\N	\N
91	CAM-A01	VLM_PENDING	medium	[Frame 1969 at 0:00:32] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 1969, "safety_status": "PENDING", "timestamp_str": "0:00:32"}	2026-03-21 00:26:05.410711+00	\N	\N
92	CAM-A01	VLM_PENDING	medium	[Frame 2148 at 0:00:35] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 2148, "safety_status": "PENDING", "timestamp_str": "0:00:35"}	2026-03-21 00:26:05.43586+00	\N	\N
93	CAM-A01	VLM_PENDING	medium	[Frame 2327 at 0:00:38] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 2327, "safety_status": "PENDING", "timestamp_str": "0:00:38"}	2026-03-21 00:26:05.464574+00	\N	\N
94	CAM-A01	VLM_PENDING	medium	[Frame 2506 at 0:00:41] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 2506, "safety_status": "PENDING", "timestamp_str": "0:00:41"}	2026-03-21 00:26:05.490169+00	\N	\N
95	CAM-A01	VLM_PENDING	medium	[Frame 2685 at 0:00:44] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 2685, "safety_status": "PENDING", "timestamp_str": "0:00:44"}	2026-03-21 00:26:05.516122+00	\N	\N
96	CAM-A01	VLM_PENDING	medium	[Frame 2864 at 0:00:47] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 2864, "safety_status": "PENDING", "timestamp_str": "0:00:47"}	2026-03-21 00:26:05.540985+00	\N	\N
97	CAM-A01	VLM_PENDING	medium	[Frame 3043 at 0:00:50] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 3043, "safety_status": "PENDING", "timestamp_str": "0:00:50"}	2026-03-21 00:26:05.566726+00	\N	\N
98	CAM-A01	VLM_PENDING	medium	[Frame 3222 at 0:00:53] — Awaiting Qwen AI analysis (GPU worker not available)	0.85	{"job_id": 8, "frame_idx": 3222, "safety_status": "PENDING", "timestamp_str": "0:00:53"}	2026-03-21 00:26:05.590935+00	\N	\N
100	CAM-A01	VLM_PENDING	medium	[Frame 179 at 0:00:02] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 179, "safety_status": "PENDING", "timestamp_str": "0:00:02"}	2026-03-21 00:33:57.450694+00	\N	\N
102	CAM-A01	VLM_PENDING	medium	[Frame 537 at 0:00:08] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 537, "safety_status": "PENDING", "timestamp_str": "0:00:08"}	2026-03-21 00:33:57.509686+00	\N	\N
104	CAM-A01	VLM_PENDING	medium	[Frame 895 at 0:00:14] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 895, "safety_status": "PENDING", "timestamp_str": "0:00:14"}	2026-03-21 00:33:57.567839+00	\N	\N
106	CAM-A01	VLM_PENDING	medium	[Frame 1253 at 0:00:20] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 1253, "safety_status": "PENDING", "timestamp_str": "0:00:20"}	2026-03-21 00:33:57.620811+00	\N	\N
108	CAM-A01	VLM_PENDING	medium	[Frame 1611 at 0:00:26] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 1611, "safety_status": "PENDING", "timestamp_str": "0:00:26"}	2026-03-21 00:33:57.67635+00	\N	\N
110	CAM-A01	VLM_PENDING	medium	[Frame 1969 at 0:00:32] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 1969, "safety_status": "PENDING", "timestamp_str": "0:00:32"}	2026-03-21 00:33:57.727587+00	\N	\N
112	CAM-A01	VLM_PENDING	medium	[Frame 2327 at 0:00:38] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 2327, "safety_status": "PENDING", "timestamp_str": "0:00:38"}	2026-03-21 00:33:57.776598+00	\N	\N
116	CAM-A01	VLM_PENDING	medium	[Frame 3043 at 0:00:50] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 3043, "safety_status": "PENDING", "timestamp_str": "0:00:50"}	2026-03-21 00:33:57.875706+00	\N	\N
119	CAM-A01	VLM_PENDING	medium	[Frame 179 at 0:00:02] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 179, "safety_status": "PENDING", "timestamp_str": "0:00:02"}	2026-03-21 00:41:51.580728+00	\N	\N
122	CAM-A01	VLM_PENDING	medium	[Frame 716 at 0:00:11] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 716, "safety_status": "PENDING", "timestamp_str": "0:00:11"}	2026-03-21 00:41:51.659002+00	\N	\N
125	CAM-A01	VLM_PENDING	medium	[Frame 1253 at 0:00:20] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 1253, "safety_status": "PENDING", "timestamp_str": "0:00:20"}	2026-03-21 00:41:51.747577+00	\N	\N
128	CAM-A01	VLM_PENDING	medium	[Frame 1790 at 0:00:29] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 1790, "safety_status": "PENDING", "timestamp_str": "0:00:29"}	2026-03-21 00:41:51.833594+00	\N	\N
131	CAM-A01	VLM_PENDING	medium	[Frame 2327 at 0:00:38] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 2327, "safety_status": "PENDING", "timestamp_str": "0:00:38"}	2026-03-21 00:41:51.91501+00	\N	\N
134	CAM-A01	VLM_PENDING	medium	[Frame 2864 at 0:00:47] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 2864, "safety_status": "PENDING", "timestamp_str": "0:00:47"}	2026-03-21 00:41:51.994946+00	\N	\N
101	CAM-A01	VLM_PENDING	medium	[Frame 358 at 0:00:05] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 358, "safety_status": "PENDING", "timestamp_str": "0:00:05"}	2026-03-21 00:33:57.481374+00	\N	\N
103	CAM-A01	VLM_PENDING	medium	[Frame 716 at 0:00:11] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 716, "safety_status": "PENDING", "timestamp_str": "0:00:11"}	2026-03-21 00:33:57.539806+00	\N	\N
105	CAM-A01	VLM_PENDING	medium	[Frame 1074 at 0:00:17] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 1074, "safety_status": "PENDING", "timestamp_str": "0:00:17"}	2026-03-21 00:33:57.595147+00	\N	\N
107	CAM-A01	VLM_PENDING	medium	[Frame 1432 at 0:00:23] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 1432, "safety_status": "PENDING", "timestamp_str": "0:00:23"}	2026-03-21 00:33:57.647822+00	\N	\N
109	CAM-A01	VLM_PENDING	medium	[Frame 1790 at 0:00:29] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 1790, "safety_status": "PENDING", "timestamp_str": "0:00:29"}	2026-03-21 00:33:57.703061+00	\N	\N
111	CAM-A01	VLM_PENDING	medium	[Frame 2148 at 0:00:35] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 2148, "safety_status": "PENDING", "timestamp_str": "0:00:35"}	2026-03-21 00:33:57.752655+00	\N	\N
113	CAM-A01	VLM_PENDING	medium	[Frame 2506 at 0:00:41] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 2506, "safety_status": "PENDING", "timestamp_str": "0:00:41"}	2026-03-21 00:33:57.800117+00	\N	\N
114	CAM-A01	VLM_PENDING	medium	[Frame 2685 at 0:00:44] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 2685, "safety_status": "PENDING", "timestamp_str": "0:00:44"}	2026-03-21 00:33:57.825337+00	\N	\N
115	CAM-A01	VLM_PENDING	medium	[Frame 2864 at 0:00:47] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 2864, "safety_status": "PENDING", "timestamp_str": "0:00:47"}	2026-03-21 00:33:57.851069+00	\N	\N
117	CAM-A01	VLM_PENDING	medium	[Frame 3222 at 0:00:53] — Start Qwen Service to get AI analysis	\N	{"job_id": 9, "frame_idx": 3222, "safety_status": "PENDING", "timestamp_str": "0:00:53"}	2026-03-21 00:33:57.900434+00	\N	\N
118	CAM-A01	VLM_PENDING	medium	[Frame 0 at 0:00:00] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 0, "safety_status": "PENDING", "timestamp_str": "0:00:00"}	2026-03-21 00:41:51.529648+00	\N	\N
120	CAM-A01	VLM_PENDING	medium	[Frame 358 at 0:00:05] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 358, "safety_status": "PENDING", "timestamp_str": "0:00:05"}	2026-03-21 00:41:51.607047+00	\N	\N
121	CAM-A01	VLM_PENDING	medium	[Frame 537 at 0:00:08] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 537, "safety_status": "PENDING", "timestamp_str": "0:00:08"}	2026-03-21 00:41:51.633035+00	\N	\N
123	CAM-A01	VLM_PENDING	medium	[Frame 895 at 0:00:14] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 895, "safety_status": "PENDING", "timestamp_str": "0:00:14"}	2026-03-21 00:41:51.687547+00	\N	\N
124	CAM-A01	VLM_PENDING	medium	[Frame 1074 at 0:00:17] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 1074, "safety_status": "PENDING", "timestamp_str": "0:00:17"}	2026-03-21 00:41:51.717684+00	\N	\N
126	CAM-A01	VLM_PENDING	medium	[Frame 1432 at 0:00:23] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 1432, "safety_status": "PENDING", "timestamp_str": "0:00:23"}	2026-03-21 00:41:51.777305+00	\N	\N
127	CAM-A01	VLM_PENDING	medium	[Frame 1611 at 0:00:26] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 1611, "safety_status": "PENDING", "timestamp_str": "0:00:26"}	2026-03-21 00:41:51.805859+00	\N	\N
129	CAM-A01	VLM_PENDING	medium	[Frame 1969 at 0:00:32] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 1969, "safety_status": "PENDING", "timestamp_str": "0:00:32"}	2026-03-21 00:41:51.860035+00	\N	\N
130	CAM-A01	VLM_PENDING	medium	[Frame 2148 at 0:00:35] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 2148, "safety_status": "PENDING", "timestamp_str": "0:00:35"}	2026-03-21 00:41:51.887637+00	\N	\N
132	CAM-A01	VLM_PENDING	medium	[Frame 2506 at 0:00:41] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 2506, "safety_status": "PENDING", "timestamp_str": "0:00:41"}	2026-03-21 00:41:51.940449+00	\N	\N
133	CAM-A01	VLM_PENDING	medium	[Frame 2685 at 0:00:44] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 2685, "safety_status": "PENDING", "timestamp_str": "0:00:44"}	2026-03-21 00:41:51.966383+00	\N	\N
135	CAM-A01	VLM_PENDING	medium	[Frame 3043 at 0:00:50] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 3043, "safety_status": "PENDING", "timestamp_str": "0:00:50"}	2026-03-21 00:41:52.02438+00	\N	\N
136	CAM-A01	VLM_PENDING	medium	[Frame 3222 at 0:00:53] — Start Qwen Service to get AI analysis	\N	{"job_id": 10, "frame_idx": 3222, "safety_status": "PENDING", "timestamp_str": "0:00:53"}	2026-03-21 00:41:52.054048+00	\N	\N
137	CAM-A01	VLM_PENDING	medium	[Frame 0 at 0:00:00] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 0, "safety_status": "PENDING", "timestamp_str": "0:00:00"}	2026-03-21 00:42:19.422484+00	\N	\N
138	CAM-A01	VLM_PENDING	medium	[Frame 179 at 0:00:02] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 179, "safety_status": "PENDING", "timestamp_str": "0:00:02"}	2026-03-21 00:42:19.473395+00	\N	\N
139	CAM-A01	VLM_PENDING	medium	[Frame 358 at 0:00:05] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 358, "safety_status": "PENDING", "timestamp_str": "0:00:05"}	2026-03-21 00:42:19.502213+00	\N	\N
140	CAM-A01	VLM_PENDING	medium	[Frame 537 at 0:00:08] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 537, "safety_status": "PENDING", "timestamp_str": "0:00:08"}	2026-03-21 00:42:19.547287+00	\N	\N
141	CAM-A01	VLM_PENDING	medium	[Frame 716 at 0:00:11] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 716, "safety_status": "PENDING", "timestamp_str": "0:00:11"}	2026-03-21 00:42:19.589611+00	\N	\N
142	CAM-A01	VLM_PENDING	medium	[Frame 895 at 0:00:14] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 895, "safety_status": "PENDING", "timestamp_str": "0:00:14"}	2026-03-21 00:42:19.623132+00	\N	\N
143	CAM-A01	VLM_PENDING	medium	[Frame 1074 at 0:00:17] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 1074, "safety_status": "PENDING", "timestamp_str": "0:00:17"}	2026-03-21 00:42:19.656737+00	\N	\N
144	CAM-A01	VLM_PENDING	medium	[Frame 1253 at 0:00:20] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 1253, "safety_status": "PENDING", "timestamp_str": "0:00:20"}	2026-03-21 00:42:19.694732+00	\N	\N
145	CAM-A01	VLM_PENDING	medium	[Frame 1432 at 0:00:23] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 1432, "safety_status": "PENDING", "timestamp_str": "0:00:23"}	2026-03-21 00:42:19.732756+00	\N	\N
146	CAM-A01	VLM_PENDING	medium	[Frame 1611 at 0:00:26] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 1611, "safety_status": "PENDING", "timestamp_str": "0:00:26"}	2026-03-21 00:42:19.766369+00	\N	\N
147	CAM-A01	VLM_PENDING	medium	[Frame 1790 at 0:00:29] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 1790, "safety_status": "PENDING", "timestamp_str": "0:00:29"}	2026-03-21 00:42:19.798451+00	\N	\N
150	CAM-A01	VLM_PENDING	medium	[Frame 2327 at 0:00:38] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 2327, "safety_status": "PENDING", "timestamp_str": "0:00:38"}	2026-03-21 00:42:19.892427+00	\N	\N
153	CAM-A01	VLM_PENDING	medium	[Frame 2864 at 0:00:47] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 2864, "safety_status": "PENDING", "timestamp_str": "0:00:47"}	2026-03-21 00:42:19.977579+00	\N	\N
148	CAM-A01	VLM_PENDING	medium	[Frame 1969 at 0:00:32] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 1969, "safety_status": "PENDING", "timestamp_str": "0:00:32"}	2026-03-21 00:42:19.831333+00	\N	\N
151	CAM-A01	VLM_PENDING	medium	[Frame 2506 at 0:00:41] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 2506, "safety_status": "PENDING", "timestamp_str": "0:00:41"}	2026-03-21 00:42:19.922235+00	\N	\N
154	CAM-A01	VLM_PENDING	medium	[Frame 3043 at 0:00:50] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 3043, "safety_status": "PENDING", "timestamp_str": "0:00:50"}	2026-03-21 00:42:20.003628+00	\N	\N
149	CAM-A01	VLM_PENDING	medium	[Frame 2148 at 0:00:35] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 2148, "safety_status": "PENDING", "timestamp_str": "0:00:35"}	2026-03-21 00:42:19.860745+00	\N	\N
152	CAM-A01	VLM_PENDING	medium	[Frame 2685 at 0:00:44] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 2685, "safety_status": "PENDING", "timestamp_str": "0:00:44"}	2026-03-21 00:42:19.949966+00	\N	\N
155	CAM-A01	VLM_PENDING	medium	[Frame 3222 at 0:00:53] — Start Qwen Service to get AI analysis	\N	{"job_id": 11, "frame_idx": 3222, "safety_status": "PENDING", "timestamp_str": "0:00:53"}	2026-03-21 00:42:20.033809+00	\N	\N
156	CAM-A01	VLM_PENDING	medium	[0:00:00] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 0, "safety_status": "PENDING", "timestamp_str": "0:00:00"}	2026-03-21 09:12:47.787672+00	\N	\N
157	CAM-A01	VLM_PENDING	medium	[0:00:02] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 179, "safety_status": "PENDING", "timestamp_str": "0:00:02"}	2026-03-21 09:12:47.832229+00	\N	\N
158	CAM-A01	VLM_PENDING	medium	[0:00:05] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 358, "safety_status": "PENDING", "timestamp_str": "0:00:05"}	2026-03-21 09:12:47.860425+00	\N	\N
159	CAM-A01	VLM_PENDING	medium	[0:00:08] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 537, "safety_status": "PENDING", "timestamp_str": "0:00:08"}	2026-03-21 09:12:47.889139+00	\N	\N
160	CAM-A01	VLM_PENDING	medium	[0:00:11] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 716, "safety_status": "PENDING", "timestamp_str": "0:00:11"}	2026-03-21 09:12:47.919678+00	\N	\N
161	CAM-A01	VLM_PENDING	medium	[0:00:14] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 895, "safety_status": "PENDING", "timestamp_str": "0:00:14"}	2026-03-21 09:12:47.950446+00	\N	\N
162	CAM-A01	VLM_PENDING	medium	[0:00:17] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 1074, "safety_status": "PENDING", "timestamp_str": "0:00:17"}	2026-03-21 09:12:47.979803+00	\N	\N
163	CAM-A01	VLM_PENDING	medium	[0:00:20] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 1253, "safety_status": "PENDING", "timestamp_str": "0:00:20"}	2026-03-21 09:12:48.007347+00	\N	\N
164	CAM-A01	VLM_PENDING	medium	[0:00:23] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 1432, "safety_status": "PENDING", "timestamp_str": "0:00:23"}	2026-03-21 09:12:48.038693+00	\N	\N
165	CAM-A01	VLM_PENDING	medium	[0:00:26] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 1611, "safety_status": "PENDING", "timestamp_str": "0:00:26"}	2026-03-21 09:12:48.070602+00	\N	\N
166	CAM-A01	VLM_PENDING	medium	[0:00:29] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 1790, "safety_status": "PENDING", "timestamp_str": "0:00:29"}	2026-03-21 09:12:48.100035+00	\N	\N
167	CAM-A01	VLM_PENDING	medium	[0:00:32] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 1969, "safety_status": "PENDING", "timestamp_str": "0:00:32"}	2026-03-21 09:12:48.129206+00	\N	\N
168	CAM-A01	VLM_PENDING	medium	[0:00:35] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 2148, "safety_status": "PENDING", "timestamp_str": "0:00:35"}	2026-03-21 09:12:48.171572+00	\N	\N
169	CAM-A01	VLM_PENDING	medium	[0:00:38] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 2327, "safety_status": "PENDING", "timestamp_str": "0:00:38"}	2026-03-21 09:12:48.216775+00	\N	\N
170	CAM-A01	VLM_PENDING	medium	[0:00:41] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 2506, "safety_status": "PENDING", "timestamp_str": "0:00:41"}	2026-03-21 09:12:48.271688+00	\N	\N
171	CAM-A01	VLM_PENDING	medium	[0:00:44] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 2685, "safety_status": "PENDING", "timestamp_str": "0:00:44"}	2026-03-21 09:12:48.310593+00	\N	\N
172	CAM-A01	VLM_PENDING	medium	[0:00:47] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 2864, "safety_status": "PENDING", "timestamp_str": "0:00:47"}	2026-03-21 09:12:48.350122+00	\N	\N
173	CAM-A01	VLM_PENDING	medium	[0:00:50] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 3043, "safety_status": "PENDING", "timestamp_str": "0:00:50"}	2026-03-21 09:12:48.380997+00	\N	\N
174	CAM-A01	VLM_PENDING	medium	[0:00:53] — Start Qwen Service to get AI analysis	\N	{"job_id": 13, "frame_idx": 3222, "safety_status": "PENDING", "timestamp_str": "0:00:53"}	2026-03-21 09:12:48.418599+00	\N	\N
176	CAM-A05	sop_violation	medium	Person A หยิบกระป๋องจากกล่อง NG (ควรหยิบจาก WAIT) — เริ่มนำกระป๋อง NG กลับเข้าสายการผลิตโดยไม่ผ่านขั้นตอนที่ถูกต้อง	\N	\N	2026-03-22 10:49:26.829239+00	73	ทำงานข้ามขั้นตอน
177	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา (ไม่พบบันทึกการตรวจสอบที่ 01:15)	\N	\N	2026-03-22 10:49:26.829239+00	76	ทำงานข้ามขั้นตอน
178	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	78	ทำงานข้ามขั้นตอน
179	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	80	ทำงานข้ามขั้นตอน
180	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	82	ทำงานข้ามขั้นตอน
181	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	84	ทำงานข้ามขั้นตอน
182	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	86	ทำงานข้ามขั้นตอน
183	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	88	ทำงานข้ามขั้นตอน
184	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	90	ทำงานข้ามขั้นตอน
185	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	92	ทำงานข้ามขั้นตอน
186	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	94	ทำงานข้ามขั้นตอน
187	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	96	ทำงานข้ามขั้นตอน
188	CAM-A05	unauthorized_person	low	Person C เดินเข้าพื้นที่ทำงาน ถือขวดน้ำ	\N	\N	2026-03-22 10:49:26.829239+00	96	บุคคลอื่นเข้าพื้นที่
189	CAM-A05	unauthorized_person	low	Person C ยังอยู่ในพื้นที่ทำงาน — ยื่นขวดน้ำให้ Person B	\N	\N	2026-03-22 10:49:26.829239+00	97	บุคคลอื่นเข้าพื้นที่
190	CAM-A05	unauthorized_person	low	Person C ยังอยู่ในพื้นที่ทำงาน — Person B รับขวดน้ำ	\N	\N	2026-03-22 10:49:26.829239+00	98	บุคคลอื่นเข้าพื้นที่
191	CAM-A05	unauthorized_person	low	Person C ยังอยู่ในพื้นที่ทำงาน	\N	\N	2026-03-22 10:49:26.829239+00	99	บุคคลอื่นเข้าพื้นที่
192	CAM-A05	hygiene_violation	medium	Person B วางขวดน้ำบนโต๊ะในพื้นที่ทำงาน	\N	\N	2026-03-22 10:49:26.829239+00	99	วางของไม่เกี่ยวข้อง
193	CAM-A05	unauthorized_person	low	Person C กำลังเดินออกจากพื้นที่ทำงาน	\N	\N	2026-03-22 10:49:26.829239+00	100	บุคคลอื่นเข้าพื้นที่
194	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	101	ทำงานข้ามขั้นตอน
195	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	103	ทำงานข้ามขั้นตอน
196	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	105	ทำงานข้ามขั้นตอน
197	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	107	ทำงานข้ามขั้นตอน
198	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	109	ทำงานข้ามขั้นตอน
199	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	111	ทำงานข้ามขั้นตอน
200	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	115	ทำงานข้ามขั้นตอน
201	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	117	ทำงานข้ามขั้นตอน
202	CAM-A05	sop_violation	medium	วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	119	ทำงานข้ามขั้นตอน
203	CAM-A05	sop_violation	medium	วางกระป๋องใบสุดท้ายจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา	\N	\N	2026-03-22 10:49:26.829239+00	123	ทำงานข้ามขั้นตอน
204	CAM-A05	near_miss	critical	Person B ยื่นมือขวาไปที่ส่วนกลางของเครื่องจักร (ขณะสายพานยังเดิน)	\N	\N	2026-03-22 10:49:26.829239+00	175	Near-Miss สายพานหนีบมือ
205	CAM-A05	ppe_violation	medium	Person B ถอดหมวกออก (ขณะยังอยู่ในพื้นที่ทำงาน)	\N	\N	2026-03-22 10:49:26.829239+00	179	ไม่ใส่อุปกรณ์ PPE
206	CAM-A05	ppe_violation	medium	Person B ยังไม่สวมหมวก (กำลังสวมคืน)	\N	\N	2026-03-22 10:49:26.829239+00	180	ไม่ใส่อุปกรณ์ PPE
207	CAM-A05	ppe_violation	medium	Person B ถอดหมวก + ถุงมือออก (สิ้นสุดการทำงาน — เครื่องยังทำงานอยู่)	\N	\N	2026-03-22 10:49:26.829239+00	215	ไม่ใส่อุปกรณ์ PPE
208	CAM-A05	ppe_violation	medium	Person B ไม่สวมหมวกและถุงมือ (ยืนพูดคุยในพื้นที่ทำงาน)	\N	\N	2026-03-22 10:49:26.829239+00	216	ไม่ใส่อุปกรณ์ PPE
209	CAM-A05	ppe_violation	medium	Person B ไม่สวมหมวกและถุงมือ (Person A ปรับเครื่องจักร)	\N	\N	2026-03-22 10:49:26.829239+00	217	ไม่ใส่อุปกรณ์ PPE
210	CAM-A05	ppe_violation	medium	Person B ไม่สวมหมวกและถุงมือ (Person A ปิดเครื่องจักร)	\N	\N	2026-03-22 10:49:26.829239+00	218	ไม่ใส่อุปกรณ์ PPE
\.


--
-- Data for Name: frame_results; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.frame_results (id, job_id, camera_id, event_id, frame_idx, timestamp_sec, timestamp_str, description, safety_status, frame_path, latency_ms, created_at) FROM stdin;
1	3	CAM-A01	1	0	0.00	0:00:00	[Frame 0 at 0:00:00] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/33afbaa0_f0000.jpg	0	2026-03-21 00:00:29.456678+00
2	3	CAM-A01	2	179	2.99	0:00:02	[Frame 179 at 0:00:02] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/b70954d0_f0179.jpg	0	2026-03-21 00:00:29.522736+00
3	3	CAM-A01	3	358	5.97	0:00:05	[Frame 358 at 0:00:05] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/6831c2a2_f0358.jpg	0	2026-03-21 00:00:29.566128+00
4	3	CAM-A01	4	537	8.96	0:00:08	[Frame 537 at 0:00:08] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/295b46a2_f0537.jpg	0	2026-03-21 00:00:29.598327+00
5	3	CAM-A01	5	716	11.95	0:00:11	[Frame 716 at 0:00:11] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/869f0a31_f0716.jpg	0	2026-03-21 00:00:29.625971+00
6	3	CAM-A01	6	895	14.93	0:00:14	[Frame 895 at 0:00:14] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/19cd461c_f0895.jpg	0	2026-03-21 00:00:29.650445+00
7	3	CAM-A01	7	1074	17.92	0:00:17	[Frame 1074 at 0:00:17] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/e346cd67_f1074.jpg	0	2026-03-21 00:00:29.67605+00
8	3	CAM-A01	8	1253	20.90	0:00:20	[Frame 1253 at 0:00:20] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/73917db8_f1253.jpg	0	2026-03-21 00:00:29.700165+00
9	3	CAM-A01	9	1432	23.89	0:00:23	[Frame 1432 at 0:00:23] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/9c355206_f1432.jpg	0	2026-03-21 00:00:29.724482+00
10	3	CAM-A01	10	1611	26.88	0:00:26	[Frame 1611 at 0:00:26] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/1c8cdbc2_f1611.jpg	0	2026-03-21 00:00:29.749089+00
11	3	CAM-A01	11	1790	29.86	0:00:29	[Frame 1790 at 0:00:29] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/c3a0c3eb_f1790.jpg	0	2026-03-21 00:00:29.774923+00
12	3	CAM-A01	12	1969	32.85	0:00:32	[Frame 1969 at 0:00:32] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/59bcc44a_f1969.jpg	0	2026-03-21 00:00:29.800329+00
13	3	CAM-A01	13	2148	35.84	0:00:35	[Frame 2148 at 0:00:35] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/0be42afd_f2148.jpg	0	2026-03-21 00:00:29.826742+00
14	3	CAM-A01	14	2327	38.82	0:00:38	[Frame 2327 at 0:00:38] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/3c5f4caf_f2327.jpg	0	2026-03-21 00:00:29.853924+00
15	3	CAM-A01	15	2506	41.81	0:00:41	[Frame 2506 at 0:00:41] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/d55bb818_f2506.jpg	0	2026-03-21 00:00:29.880934+00
16	3	CAM-A01	16	2685	44.79	0:00:44	[Frame 2685 at 0:00:44] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/d3da19da_f2685.jpg	0	2026-03-21 00:00:29.907847+00
17	3	CAM-A01	17	2864	47.78	0:00:47	[Frame 2864 at 0:00:47] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/b560cc87_f2864.jpg	0	2026-03-21 00:00:29.934901+00
18	3	CAM-A01	18	3043	50.77	0:00:50	[Frame 3043 at 0:00:50] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/75e8e8a2_f3043.jpg	0	2026-03-21 00:00:29.960423+00
19	3	CAM-A01	19	3222	53.75	0:00:53	[Frame 3222 at 0:00:53] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/ea65bede_f3222.jpg	0	2026-03-21 00:00:29.988231+00
20	4	CAM-A04	20	0	0.00	0:00:00	I'm sorry, but I cannot provide a detailed description of a scene without being able to see it. Please provide me with more information about the scene you would like me to describe.	SAFE	\N	4004	2026-03-21 00:03:50.404438+00
21	4	CAM-A04	21	71	2.96	0:00:02	In the image provided, there is a black-and-white photograph of a factory floor with several workers visible. Here is a detailed description:\n\n1. **Workers Visible and Their PPE**:\n   - There are multiple workers on the factory floor. They are wearing standard factory attire, which typically includes:\n     - **Helmet**: The workers are wearing hard hats to protect their heads from potential impacts.\n     - **Vest**: Many workers are wearing reflective vests to enhance visibility.\n     - **Gloves**: Most workers are wearing gloves for protection against sharp objects and chemicals.\n     - **Boots**: Some workers are wearing sturdy work boots to provide ankle support and protect their feet.\n\n2. **Equipment and Machinery**:\n   - The factory floor has various pieces of equipment and machinery. Notable items include:\n     - **Forklifts**: Several forklifts are present, used for moving heavy materials around the facility.\n     - **Conveyors**: There are conveyor belts that transport goods through different sections of the factory.\n     - **Workstations**: Workers are seen at various stations where they perform tasks such as assembly, inspection, or packaging.\n\n3. **Safety Hazards or Violations**:\n   - **Safety Hazards**:\n     - **Ladders**: There are ladders visible, which can be used for accessing higher areas but require careful handling to avoid falls.\n     - **Stairs**: Stairs leading to different levels of the factory need to be kept	SAFE	\N	17416	2026-03-21 00:03:50.404438+00
22	4	CAM-A04	22	142	5.92	0:00:05	In the image, there is a worker operating a yellow forklift near stacks of wooden pallets and green shipping containers. The worker is wearing a black shirt, blue jeans, and a yellow hard hat with a face shield. They are also wearing gloves and sturdy work boots.\n\nThe equipment and machinery present include the yellow forklift, which is being used to move the pallets. There are no other pieces of machinery visible in the image.\n\nThere are no immediate safety hazards or violations observed in the image. The worker appears to be following proper safety protocols by wearing appropriate PPE and working near the equipment.\n\nOverall, the safety status of the scene is considered SAFE.	SAFE	\N	8238	2026-03-21 00:03:50.404438+00
23	4	CAM-A04	23	213	8.88	0:00:08	In the image, there are three workers present:\n\n1. **Workers Visible and Their PPE**:\n   - The worker on the left is wearing a black shirt, blue jeans, and a high-visibility orange vest. He is sitting on the ground with his hands clasped together.\n   - The worker in the middle is wearing a yellow safety vest, blue jeans, and brown work boots. They appear to be kneeling or crouching down.\n   - The worker on the right is wearing a black shirt, blue jeans, and black work boots. He is standing next to a yellow forklift.\n\n2. **Equipment and Machinery**:\n   - There is a yellow forklift parked near the workers.\n   - In the background, there are stacks of pallets and shipping containers, indicating an industrial setting.\n\n3. **Safety Hazards or Violations**:\n   - The worker on the left is sitting on the ground without proper footwear, which could lead to slipping or injury.\n   - The worker in the middle is kneeling or crouching down, which may not be the safest position for handling equipment or materials.\n   - The worker on the right is standing next to the forklift, but it is unclear if they are operating it safely.\n\n4. **Overall Safety Status**:\n   - **WARNING**: The workers' positions and the presence of the forklift suggest that there might be a risk of accidents or injuries. The worker on the left should wear	WARNING	\N	18081	2026-03-21 00:03:50.404438+00
30	5	CAM-A02	30	0	0.00	0:00:00	[Frame 0 at 0:00:00] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/a44baf0b_f0000.jpg	0	2026-03-21 00:04:41.587916+00
24	4	CAM-A04	24	284	11.85	0:00:11	**Scene Description:**\n\nThe scene depicts a forklift moving along a concrete floor outside a large industrial building. The forklift is yellow with black accents and is being operated by a worker who is wearing a dark-colored shirt, sunglasses, and a helmet. The worker is also wearing gloves and boots.\n\n**Workers Visible and Their PPE:**\n- **Worker:** The worker operating the forklift is wearing a helmet, a high-visibility vest, gloves, and boots.\n- **Safety Vest:** The worker is wearing a high-visibility vest, which is essential for visibility in industrial environments.\n- **Gloves:** The worker is wearing gloves to protect their hands from potential injuries.\n- **Boots:** The worker is wearing sturdy boots suitable for industrial work.\n\n**Equipment and Machinery:**\n- **Forklift:** The primary piece of equipment in the scene is a yellow forklift.\n- **Building:** The background features a large industrial building with multiple doors and windows, indicating it might be a warehouse or manufacturing facility.\n- **Conveyor Belt:** There is a conveyor belt visible in the background, suggesting that the area might involve material handling and transportation.\n\n**Safety Hazards or Violations:**\n- **Helmet:** The worker is wearing a helmet, which is appropriate for the task but should be worn at all times when operating machinery.\n- **High-Visibility Vest:** The high-visibility vest is necessary for the worker to be easily seen by others, especially	SAFE	\N	18018	2026-03-21 00:03:50.404438+00
25	4	CAM-A04	25	355	14.81	0:00:14	### Scene Description\n\n**1. Workers Visible and Their PPE:**\n- **Workers:** There is one worker visible in the image.\n- **PPE:** The worker is wearing a helmet, a high-visibility vest, gloves, and work boots.\n\n**2. Equipment and Machinery:**\n- **Forklift:** A yellow Hyster forklift is prominently featured in the foreground. It appears to be parked or moving slowly on a concrete surface.\n- **Safety Gear:** The forklift has a blue safety guard attached to its front end, which likely serves as a protective barrier against potential hazards.\n\n**3. Safety Hazards or Violations:**\n- **Hazard:** The forklift is positioned near a building with open doors, suggesting that it might be entering or exiting a warehouse or industrial facility.\n- **Violation:** There is no visible warning sign or hazard indicator on the forklift, which could indicate that it is not properly marked for entry into restricted areas.\n\n**4. Overall Safety Status:**\n- **Status:** **WARNING** - The forklift is in an area where it should not be entering, and there is no visible warning system to alert workers of the potential hazard. The presence of the worker without proper safety gear also indicates a lack of adherence to safety protocols.\n\n### Summary\nThe scene depicts a forklift in an industrial setting, but it is in an area where it should not be entering. The forklift is equipped	WARNING	\N	17502	2026-03-21 00:03:50.404438+00
26	4	CAM-A04	26	426	17.77	0:00:17	### Scene Description:\n\n**1. Workers Visible and Their PPE:**\n- There is one worker visible in the image.\n- The worker is wearing a yellow safety vest and a helmet.\n- The worker is also wearing gloves and boots.\n\n**2. Equipment and Machinery:**\n- There is a forklift parked near the building.\n- A conveyor belt system is visible, running horizontally across the image.\n- The conveyor belt appears to be in operation, with materials moving along it.\n\n**3. Safety Hazards or Violations:**\n- **Safety Vest:** The worker is wearing a yellow safety vest, which is appropriate for the environment.\n- **Helmet:** The worker is wearing a helmet, which is necessary for head protection.\n- **Gloves:** The worker is wearing gloves, which is important for handling materials safely.\n- **Boots:** The worker is wearing boots, which provide foot protection.\n- **Forklift:** The forklift is parked near the building, which could pose a risk if not properly secured or if the worker is not aware of its presence.\n- **Conveyor Belt:** The conveyor belt is in operation, which could pose a risk if the worker is not cautious about moving parts or if they are not aware of the conveyor belt's location.\n\n**4. Overall Safety Status:**\n- **SAFE:** The worker is wearing appropriate PPE, and there are no immediate safety hazards visible in the image. However, the worker should remain vigilant and	SAFE	\N	16351	2026-03-21 00:03:50.404438+00
27	4	CAM-A04	27	497	20.73	0:00:20	### Scene Description:\n\n**1. Workers Visible and Their PPE:**\n- There are two workers visible in the image.\n  - The worker on the left is wearing a yellow hard hat, a high-visibility vest, gloves, and work boots.\n  - The worker on the right is also wearing a yellow hard hat, a high-visibility vest, gloves, and work boots.\n\n**2. Equipment and Machinery:**\n- A green forklift is parked near the workers.\n- There is a conveyor belt running horizontally along the right side of the image.\n- The conveyor belt appears to be empty at the moment the image was taken.\n\n**3. Safety Hazards or Violations:**\n- **Safety Helmet:** Both workers are wearing safety helmets, which is correct.\n- **High-Visibility Vests:** Both workers are wearing high-visibility vests, which is also correct.\n- **Gloves:** Both workers are wearing gloves, which is necessary for protection.\n- **Work Boots:** Both workers are wearing work boots, which is appropriate for industrial work.\n- **Forklift:** The forklift is parked safely away from the workers, but it is important that it is not parked too close to moving equipment or pedestrians.\n- **Conveyor Belt:** The conveyor belt is empty and appears to be in good condition, but it should be regularly inspected for any potential issues.\n\n**4. Overall Safety Status:**\n- **SAFE:** The workers are wearing appropriate personal protective	SAFE	\N	16953	2026-03-21 00:03:50.404438+00
28	4	CAM-A04	28	568	23.69	0:00:23	### Scene Description\n\n**1. Workers Visible and Their PPE:**\n- **Worker 1:** \n  - Wearing a yellow safety vest with reflective stripes.\n  - Wearing blue jeans.\n  - Wearing black work boots.\n  - Holding a broom.\n\n- **Worker 2:**\n  - Wearing a yellow safety vest with reflective stripes.\n  - Wearing blue jeans.\n  - Wearing black work boots.\n  - Holding a dustpan.\n\n**2. Equipment and Machinery:**\n- The warehouse is spacious with concrete flooring.\n- There are stacks of white bags on the left side of the image.\n- The background features wooden walls and a concrete floor.\n- No visible machinery or equipment in the immediate foreground.\n\n**3. Safety Hazards or Violations:**\n- **Safety Vest:** Both workers are wearing yellow safety vests, which is appropriate for the warehouse environment.\n- **Gloves:** Both workers are wearing gloves, which is necessary for handling materials and cleaning.\n- **Boots:** Both workers are wearing black work boots, which provide good traction and protection.\n- **Helmet:** Neither worker is wearing a helmet, which is a violation as they are working in an area where head injuries could occur due to falling objects or debris.\n- **Forklifts/Cargo Handling:** There are no visible forklifts or cargo handling equipment in the image.\n- **Safety Guards:** There are no safety guards or barriers around the workers,	SAFE	\N	17124	2026-03-21 00:03:50.404438+00
29	4	CAM-A04	29	639	26.65	0:00:26	In the image, there is a worker using a broom to sweep gravel off a concrete floor. The worker is wearing work boots and jeans, but no other PPE such as a helmet, vest, gloves, or safety shoes is visible.\n\nThere are no other workers or equipment visible in the image.\n\nThe safety hazard in this scene is the lack of proper PPE, specifically gloves and safety shoes. This could lead to injuries if the worker slips on the gravel or if they accidentally step on the gravel while sweeping.\n\nOverall, the safety status of this scene is "WARNING" due to the lack of appropriate PPE.	WARNING	\N	7091	2026-03-21 00:03:50.404438+00
31	5	CAM-A02	31	179	2.99	0:00:02	[Frame 179 at 0:00:02] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/c0df1551_f0179.jpg	0	2026-03-21 00:04:41.648357+00
33	5	CAM-A02	33	537	8.96	0:00:08	[Frame 537 at 0:00:08] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/5a5586ed_f0537.jpg	0	2026-03-21 00:04:41.732563+00
35	5	CAM-A02	35	895	14.93	0:00:14	[Frame 895 at 0:00:14] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/7fa27a3d_f0895.jpg	0	2026-03-21 00:04:41.801866+00
37	5	CAM-A02	37	1253	20.90	0:00:20	[Frame 1253 at 0:00:20] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/ca2f766d_f1253.jpg	0	2026-03-21 00:04:41.865439+00
39	5	CAM-A02	39	1611	26.88	0:00:26	[Frame 1611 at 0:00:26] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/a492d7ef_f1611.jpg	0	2026-03-21 00:04:42.002911+00
41	5	CAM-A02	41	1969	32.85	0:00:32	[Frame 1969 at 0:00:32] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/27ba9579_f1969.jpg	0	2026-03-21 00:04:42.080909+00
43	5	CAM-A02	43	2327	38.82	0:00:38	[Frame 2327 at 0:00:38] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/550ad072_f2327.jpg	0	2026-03-21 00:04:42.229497+00
45	5	CAM-A02	45	2685	44.79	0:00:44	[Frame 2685 at 0:00:44] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/dda94f4d_f2685.jpg	0	2026-03-21 00:04:42.334802+00
47	5	CAM-A02	47	3043	50.77	0:00:50	[Frame 3043 at 0:00:50] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/448eb217_f3043.jpg	0	2026-03-21 00:04:42.395472+00
49	6	CAM-A02	49	0	0.00	0:00:00	[Frame 0 at 0:00:00] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/f72f3f7d_f0000.jpg	0	2026-03-21 00:07:53.684001+00
51	6	CAM-A02	51	358	5.97	0:00:05	[Frame 358 at 0:00:05] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/7e9582ff_f0358.jpg	0	2026-03-21 00:07:53.747515+00
53	6	CAM-A02	53	716	11.95	0:00:11	[Frame 716 at 0:00:11] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/397ad703_f0716.jpg	0	2026-03-21 00:07:53.804059+00
55	6	CAM-A02	55	1074	17.92	0:00:17	[Frame 1074 at 0:00:17] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/847be0a5_f1074.jpg	0	2026-03-21 00:07:53.860591+00
57	6	CAM-A02	57	1432	23.89	0:00:23	[Frame 1432 at 0:00:23] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/2311520a_f1432.jpg	0	2026-03-21 00:07:53.913177+00
59	6	CAM-A02	59	1790	29.86	0:00:29	[Frame 1790 at 0:00:29] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/eb4b2704_f1790.jpg	0	2026-03-21 00:07:53.96681+00
61	6	CAM-A02	61	2148	35.84	0:00:35	[Frame 2148 at 0:00:35] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/71bd7b67_f2148.jpg	0	2026-03-21 00:07:54.02381+00
63	6	CAM-A02	63	2506	41.81	0:00:41	[Frame 2506 at 0:00:41] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/a1322bdf_f2506.jpg	0	2026-03-21 00:07:54.076532+00
65	6	CAM-A02	65	2864	47.78	0:00:47	[Frame 2864 at 0:00:47] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/072c2b14_f2864.jpg	0	2026-03-21 00:07:54.12948+00
67	6	CAM-A02	67	3222	53.75	0:00:53	[Frame 3222 at 0:00:53] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/68f8fe50_f3222.jpg	0	2026-03-21 00:07:54.183148+00
32	5	CAM-A02	32	358	5.97	0:00:05	[Frame 358 at 0:00:05] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/48f9ab20_f0358.jpg	0	2026-03-21 00:04:41.697583+00
34	5	CAM-A02	34	716	11.95	0:00:11	[Frame 716 at 0:00:11] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/31885b91_f0716.jpg	0	2026-03-21 00:04:41.758091+00
36	5	CAM-A02	36	1074	17.92	0:00:17	[Frame 1074 at 0:00:17] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/d041ac24_f1074.jpg	0	2026-03-21 00:04:41.829386+00
38	5	CAM-A02	38	1432	23.89	0:00:23	[Frame 1432 at 0:00:23] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/c4b127b0_f1432.jpg	0	2026-03-21 00:04:41.924169+00
40	5	CAM-A02	40	1790	29.86	0:00:29	[Frame 1790 at 0:00:29] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/170e0545_f1790.jpg	0	2026-03-21 00:04:42.038423+00
42	5	CAM-A02	42	2148	35.84	0:00:35	[Frame 2148 at 0:00:35] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/0f731309_f2148.jpg	0	2026-03-21 00:04:42.169185+00
44	5	CAM-A02	44	2506	41.81	0:00:41	[Frame 2506 at 0:00:41] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/7a86b696_f2506.jpg	0	2026-03-21 00:04:42.296473+00
46	5	CAM-A02	46	2864	47.78	0:00:47	[Frame 2864 at 0:00:47] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/1faa69ce_f2864.jpg	0	2026-03-21 00:04:42.364449+00
48	5	CAM-A02	48	3222	53.75	0:00:53	[Frame 3222 at 0:00:53] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/a3e4c5cf_f3222.jpg	0	2026-03-21 00:04:42.431597+00
50	6	CAM-A02	50	179	2.99	0:00:02	[Frame 179 at 0:00:02] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/3622b9c0_f0179.jpg	0	2026-03-21 00:07:53.711545+00
52	6	CAM-A02	52	537	8.96	0:00:08	[Frame 537 at 0:00:08] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/cfdc2d80_f0537.jpg	0	2026-03-21 00:07:53.777476+00
54	6	CAM-A02	54	895	14.93	0:00:14	[Frame 895 at 0:00:14] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/677aa8d0_f0895.jpg	0	2026-03-21 00:07:53.833961+00
56	6	CAM-A02	56	1253	20.90	0:00:20	[Frame 1253 at 0:00:20] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/13df4fd2_f1253.jpg	0	2026-03-21 00:07:53.887565+00
58	6	CAM-A02	58	1611	26.88	0:00:26	[Frame 1611 at 0:00:26] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/3bba94c7_f1611.jpg	0	2026-03-21 00:07:53.939947+00
60	6	CAM-A02	60	1969	32.85	0:00:32	[Frame 1969 at 0:00:32] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/e026a786_f1969.jpg	0	2026-03-21 00:07:53.995596+00
62	6	CAM-A02	62	2327	38.82	0:00:38	[Frame 2327 at 0:00:38] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/79d8754a_f2327.jpg	0	2026-03-21 00:07:54.050614+00
64	6	CAM-A02	64	2685	44.79	0:00:44	[Frame 2685 at 0:00:44] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/ab2af82c_f2685.jpg	0	2026-03-21 00:07:54.103295+00
66	6	CAM-A02	66	3043	50.77	0:00:50	[Frame 3043 at 0:00:50] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A02/8f7ba0fc_f3043.jpg	0	2026-03-21 00:07:54.156385+00
68	7	CAM-A04	68	0	0.00	0:00:00	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Positioned near the left side of the image, wearing a white shirt, blue jeans, and a red helmet with a face mask. They are also wearing gloves and shoes.\n  - **Worker 2**: Positioned closer to the center-right of the image, wearing a pink shirt, blue jeans, and a red helmet with a face mask. They are also wearing gloves and shoes.\n\n#### 2. Equipment and Machinery\n- **Forklift**: A forklift is present in the center of the image, moving on the floor. The forklift has an orange body and is equipped with a fork.\n- **Conveyors**: Several conveyor belts are visible in the background, running horizontally across the warehouse.\n- **Storage Bins**: Various storage bins are scattered around the area, some containing cylindrical objects that appear to be rolls of paper or fabric.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Operation**: The forklift is operating within the warehouse, which is generally safe as long as it follows proper procedures. However, there is a risk of collision if the forklift operator does not maintain a safe distance from other equipment or workers.\n- **Storage Area**: The storage bins are stacked in a way that could potentially cause accidents if they were to tip over	SAFE	\N	21513	2026-03-21 00:24:43.951632+00
69	7	CAM-A04	69	299	4.99	0:00:04	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a red helmet, white shirt, blue jeans, and yellow gloves.\n  - **Worker 2**: Wearing a pink helmet, blue shirt, blue jeans, and yellow gloves.\n\n#### 2. Equipment and Machinery\n- **Forklift**: An orange forklift is parked near the center of the image, with its forks extended towards the ground.\n- **Conveyors**: Several conveyor belts are present, running horizontally across the floor.\n- **Storage Bins**: Various storage bins are scattered around the area, containing materials and equipment.\n- **Safety Barriers**: Metal barriers are placed around some areas to prevent access.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Operation**: The forklift is operating within an industrial setting but without any visible safety barriers or guards around it.\n- **Storage Area**: Some storage bins are stacked too high, which could pose a risk if they were to fall.\n- **Cable Management**: There are exposed cables on the floor, which can be a tripping hazard.\n- **Lack of Safety Guards**: Forklifts should have safety guards to prevent injuries from falling objects.\n- **Storage Bin Stacking**: The storage bins are stacked too high, increasing the risk of falling.\n\n#### 4. Overall	SAFE	\N	19960	2026-03-21 00:24:43.951632+00
70	7	CAM-A04	70	598	9.98	0:00:09	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a red helmet, white shirt, black pants, and gloves.\n  - **Worker 2**: Wearing a red helmet, pink shirt, black pants, and gloves.\n\n#### 2. Equipment and Machinery\n- **Forklift**: An orange forklift is present in the center of the image, moving along the floor.\n- **Conveyors**: Several large cylindrical objects, possibly rolls of material, are aligned on the floor.\n- **Storage Bins**: Various storage bins are scattered around the area, some containing white containers.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Operation**: The forklift is operating within the warehouse, which is generally safe as long as it follows proper procedures.\n- **Cylindrical Objects**: The large cylindrical objects on the floor pose a potential hazard if they roll over or are accidentally stepped on by workers.\n- **Storage Bins**: Some storage bins are open, which could lead to items falling out or creating tripping hazards.\n- **Safety Signs**: There are no visible safety signs or warning labels that might indicate specific hazards or require additional precautions.\n\n#### 4. Overall Safety Status\n- **SAFE**: The workers are wearing appropriate PPE, and the equipment appears to be in good working condition. However	WARNING	\N	20849	2026-03-21 00:24:43.951632+00
71	7	CAM-A04	71	897	14.96	0:00:14	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Positioned near the left side of the image, wearing a white shirt, red helmet, and blue jeans. They appear to be operating the forklift.\n  - **Worker 2**: Positioned near the right side of the image, wearing a pink shirt, blue jeans, and a yellow hard hat. They seem to be engaged in some activity related to the large cylindrical objects.\n\n#### 2. Equipment and Machinery\n- **Forklift**: The primary piece of equipment is an orange forklift positioned centrally in the image. It has a red seat and is equipped with forks that are currently in use.\n- **Large Cylindrical Objects**: Several large cylindrical objects are present on the right side of the image. These objects are likely made of metal or another durable material, possibly used for industrial purposes.\n- **Conveyor Belt**: A conveyor belt is visible on the right side of the image, running horizontally across the floor. It appears to be part of the factory's production line.\n\n#### 3. Safety Hazards or Violations\n- **Safety Helmet**: Both workers are wearing helmets, which is a positive aspect of their safety measures.\n- **Forklift Operation**: The forklift operator is using the forks correctly, but it’s important to ensure that the forks are not obstructing	SAFE	\N	20201	2026-03-21 00:24:43.951632+00
99	9	CAM-A01	99	0	0.00	0:00:00	[Frame 0 at 0:00:00] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/ae77dbec_f0000.jpg	0	2026-03-21 00:33:57.396151+00
101	9	CAM-A01	101	358	5.97	0:00:05	[Frame 358 at 0:00:05] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/4f18c2bd_f0358.jpg	0	2026-03-21 00:33:57.481374+00
72	7	CAM-A04	72	1196	19.95	0:00:19	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a white shirt, red helmet, and blue jeans. They appear to be operating a forklift.\n  - **Worker 2**: Wearing a pink shirt and blue jeans. They are standing near the forklift, possibly overseeing the operation.\n\n#### 2. Equipment and Machinery\n- **Forklift**: The primary piece of equipment is an orange forklift with the brand name "JAC" visible on its side. It is positioned in the center of the image, moving along the floor.\n- **Conveyors**: There are several large cylindrical objects that appear to be conveyor belts or storage units. These are lined up along the right side of the image.\n- **Storage Units**: Several stacks of white containers are visible in the background, likely used for storage or packaging.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Operation**: The forklift is operating within the warehouse, but it appears to be moving at a slow pace. However, there is no visible indication of any safety protocols being followed, such as speed limits or designated areas for forklift use.\n- **Worker Safety**: Both workers are wearing appropriate PPE, including helmets and gloves. However, Worker 2 is not wearing a reflective vest, which is recommended for	SAFE	\N	20531	2026-03-21 00:24:43.951632+00
73	7	CAM-A04	73	1495	24.94	0:00:24	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a red helmet, white shirt, blue jeans, and work boots.\n  - **Worker 2**: Wearing a pink shirt, blue jeans, and work boots.\n\n#### 2. Equipment and Machinery\n- **Forklift**: An orange forklift is parked near the workers. It has a red seat and is equipped with a fork lift.\n- **Conveyor Belt**: A conveyor belt is present in the background, running horizontally across the warehouse.\n- **Storage Racks**: Several storage racks are visible, holding various items.\n- **Safety Barriers**: There are safety barriers around the forklift to prevent accidents.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Operation**: The forklift is parked in an area where it could potentially cause damage to other equipment or materials if moved.\n- **Storage Area**: The storage racks are not properly secured, which could lead to items falling off and causing injuries.\n- **Work Boots**: Both workers are wearing appropriate work boots, but they should also be wearing steel-toed shoes for additional protection.\n- **Forklift Operator**: The forklift operator is wearing a helmet, but proper gloves and protective clothing are recommended forklift operations.\n\n#### 4. Overall Safety Status\n**Status**:	SAFE	\N	20649	2026-03-21 00:24:43.951632+00
74	7	CAM-A04	74	1794	29.93	0:00:29	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Worker 1**: \n  - **Position**: Near the right side of the image.\n  - **PPE**: Wearing a red helmet, white shirt, blue jeans, and gloves.\n  \n- **Worker 2**:\n  - **Position**: Near the center-left of the image.\n  - **PPE**: Wearing a red helmet, white shirt, blue jeans, and gloves.\n\n#### 2. Equipment and Machinery\n- **Forklift**: Positioned near the center of the image, with a worker operating it.\n- **Conveyor Belt**: Located on the left side of the image, running horizontally across the warehouse.\n- **Storage Racks**: Positioned along the walls, holding stacks of materials.\n- **Safety Barriers**: Present around the conveyor belt to prevent workers from entering unsafe areas.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Operation**: The forklift is positioned near the conveyor belt, which could pose a risk if the operator is not vigilant.\n- **Storage Area**: The storage racks are stacked high, which can be dangerous if workers are not careful when moving around them.\n- **Safety Barriers**: The barriers around the conveyor belt are present but may need regular inspection to ensure they are functioning properly.\n\n#### 4. Overall Safety Status\n- **Status**: **WARNING**\n- **Reason**: The presence of workers	DANGER	\N	19725	2026-03-21 00:24:43.951632+00
75	7	CAM-A04	75	2093	34.92	0:00:34	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There are two workers visible in the image.\n  - **Worker 1**: Wearing a red helmet, white shirt, black pants, and gloves.\n  - **Worker 2**: Wearing a red helmet, pink shirt, blue jeans, and gloves.\n\n#### 2. Equipment and Machinery\n- **Forklift**: An orange forklift is parked near the workers. It has a red seat and is equipped with a fork.\n- **Conveyors**: Several large cylindrical objects are on the ground, likely conveyor belts or storage units.\n- **Storage Units**: There are stacks of white rectangular items in the background, possibly pallets or crates.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Safety**: The forklift is parked in an area where it could potentially cause damage to other equipment or materials if moved.\n- **Storage Area**: The storage units are stacked closely together, which could lead to accidents if they fall.\n- **Worker Positioning**: Worker 2 is standing too close to the forklift, which could be a safety hazard if the forklift were to move unexpectedly.\n- **Safety Gear**: Both workers are wearing appropriate PPE, but there is no visible safety harness or other protective gear that might be necessary in this environment.\n\n#### 4. Overall Safety Status\n**Status**: **WARNING**\n\nThe	WARNING	\N	21362	2026-03-21 00:24:43.951632+00
76	7	CAM-A04	76	2392	39.91	0:00:39	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There is one worker visible in the image.\n- **PPE**:\n  - The worker is wearing a red helmet.\n  - The worker is also wearing a white shirt and blue jeans.\n\n#### 2. Equipment and Machinery\n- **Forklift**: A forklift is present in the image, positioned near the center of the warehouse.\n- **Conveyors**: There are several large cylindrical objects on the right side of the image, which appear to be conveyor belts or some kind of industrial equipment.\n- **Storage**: Various stacks of materials are visible in the background, indicating that the warehouse is used for storage.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Safety**: The forklift is parked inside the warehouse, which is generally not recommended as it can obstruct walkways and make it difficult for other workers to move around safely.\n- **Material Handling**: The worker is operating the forklift, but there is no visible protective barrier or guard around the forklift, which could pose a risk if the forklift were to tip over.\n- **Cylindrical Objects**: The large cylindrical objects on the right side of the image are placed directly on the floor without any protective barriers, which could be a safety hazard if they were to roll or shift.\n\n#### 4. Overall Safety Status\n- **Status**: **WARNING	WARNING	\N	20329	2026-03-21 00:24:43.951632+00
100	9	CAM-A01	100	179	2.99	0:00:02	[Frame 179 at 0:00:02] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/a0cc50fd_f0179.jpg	0	2026-03-21 00:33:57.450694+00
102	9	CAM-A01	102	537	8.96	0:00:08	[Frame 537 at 0:00:08] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/b7dffd02_f0537.jpg	0	2026-03-21 00:33:57.509686+00
103	9	CAM-A01	103	716	11.95	0:00:11	[Frame 716 at 0:00:11] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/7cda8198_f0716.jpg	0	2026-03-21 00:33:57.539806+00
104	9	CAM-A01	104	895	14.93	0:00:14	[Frame 895 at 0:00:14] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/fb24f890_f0895.jpg	0	2026-03-21 00:33:57.567839+00
105	9	CAM-A01	105	1074	17.92	0:00:17	[Frame 1074 at 0:00:17] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/8f1dccaa_f1074.jpg	0	2026-03-21 00:33:57.595147+00
77	7	CAM-A04	77	2691	44.89	0:00:44	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Worker 1**: \n  - **Position**: Standing near the forklift.\n  - **PPE**: Red helmet, white shirt, blue jeans, and work boots.\n\n- **Worker 2**:\n  - **Position**: Walking towards the right side of the image.\n  - **PPE**: Pink shirt, blue jeans, and work boots.\n\n#### 2. Equipment and Machinery\n- **Forklift**: Orange forklift with a red operator's cab, positioned on the left side of the image.\n- **Conveyors**: Several large cylindrical objects on conveyor belts, aligned horizontally across the bottom of the image.\n- **Storage Area**: Various stacks of materials and equipment in the background, indicating an industrial setting.\n\n#### 3. Safety Hazards or Violations\n- **Safety Helmet**: Both workers are wearing helmets, which is appropriate.\n- **Work Boots**: Both workers are wearing work boots, which is also appropriate.\n- **Forklift Operation**: The forklift is parked and appears to be in operation, but there is no visible operator.\n- **Cylindrical Objects**: The cylindrical objects on the conveyor belts could pose a risk if they were to fall or roll.\n- **Material Handling**: The worker near the forklift might not be following proper lifting techniques, as the load appears to be heavy.\n\n#### 4. Overall Safety Status	SAFE	\N	18570	2026-03-21 00:24:43.951632+00
78	7	CAM-A04	78	2990	49.88	0:00:49	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Worker 1**: \n  - **Position**: Left side of the image.\n  - **Appearance**: Wearing a red helmet, orange safety vest, and gloves.\n  - **Activity**: Operating a forklift.\n\n- **Worker 2**:\n  - **Position**: Right side of the image.\n  - **Appearance**: Wearing a pink shirt, blue jeans, and no visible PPE except for a white helmet.\n  - **Activity**: Standing near the forklift.\n\n#### 2. Equipment and Machinery\n- **Forklift**: Positioned on the left side of the image, actively moving a large roll of material.\n- **Conveyor Belt**: Located in the background, running horizontally across the warehouse.\n- **Storage Bins**: Positioned at the back of the warehouse, containing various materials.\n- **Workbenches**: Found in the middle of the warehouse, likely used for assembly or maintenance tasks.\n\n#### 3. Safety Hazards or Violations\n- **Forklift Safety**: The forklift is operating within the warehouse, but there is no visible safety barrier or warning signs to prevent it from entering restricted areas.\n- **Material Handling**: The worker operating the forklift is not wearing any protective gear other than a helmet, which is insufficient for handling heavy materials.\n- **Storage Area**: The storage bins are stacked closely together, which could lead	WARNING	\N	19977	2026-03-21 00:24:43.951632+00
79	7	CAM-A04	79	3289	54.87	0:00:54	### Description of the Scene\n\n#### 1. Workers Visible and Their PPE\n- **Workers**: There is one worker visible in the image.\n- **PPE**: The worker is wearing a pink shirt, blue jeans, and a red safety vest. They also have a helmet on.\n\n#### 2. Equipment and Machinery\n- **Forklift**: A forklift is parked near the left side of the image, partially visible.\n- **Conveyors**: There are several large rolls of material on the right side of the image, likely on conveyor belts.\n- **Storage**: Various stacks of materials are seen in the background, indicating a storage area.\n\n#### 3. Safety Hazards or Violations\n- **Safety Vest**: The worker is wearing a red safety vest, which is appropriate for the environment.\n- **Helmet**: The worker is wearing a helmet, which is necessary for protection against head injuries.\n- **Material Handling**: The forklift is parked near the workers, which could pose a risk if it moves unexpectedly.\n- **Storage Area**: The stacks of materials in the background need to be secured properly to prevent accidents.\n\n#### 4. Overall Safety Status\n- **SAFE**: The worker is wearing appropriate PPE, and the equipment appears to be in good condition. However, there are potential hazards such as the forklift and the stacks of materials that need to be addressed.\n\n### Summary\nThe scene depicts a well-organized industrial setting with a	SAFE	\N	19446	2026-03-21 00:24:43.951632+00
80	8	CAM-A01	80	0	0.00	0:00:00	[Frame 0 at 0:00:00] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/16f0a458_f0000.jpg	0	2026-03-21 00:26:05.117914+00
81	8	CAM-A01	81	179	2.99	0:00:02	[Frame 179 at 0:00:02] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/8abfcc8a_f0179.jpg	0	2026-03-21 00:26:05.153878+00
82	8	CAM-A01	82	358	5.97	0:00:05	[Frame 358 at 0:00:05] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/e666827b_f0358.jpg	0	2026-03-21 00:26:05.182872+00
83	8	CAM-A01	83	537	8.96	0:00:08	[Frame 537 at 0:00:08] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/614bd643_f0537.jpg	0	2026-03-21 00:26:05.208296+00
84	8	CAM-A01	84	716	11.95	0:00:11	[Frame 716 at 0:00:11] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/9e414f65_f0716.jpg	0	2026-03-21 00:26:05.233125+00
85	8	CAM-A01	85	895	14.93	0:00:14	[Frame 895 at 0:00:14] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/47d73686_f0895.jpg	0	2026-03-21 00:26:05.258681+00
86	8	CAM-A01	86	1074	17.92	0:00:17	[Frame 1074 at 0:00:17] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/c1790328_f1074.jpg	0	2026-03-21 00:26:05.284294+00
87	8	CAM-A01	87	1253	20.90	0:00:20	[Frame 1253 at 0:00:20] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/b70f13c8_f1253.jpg	0	2026-03-21 00:26:05.310273+00
88	8	CAM-A01	88	1432	23.89	0:00:23	[Frame 1432 at 0:00:23] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/e1133c63_f1432.jpg	0	2026-03-21 00:26:05.335323+00
89	8	CAM-A01	89	1611	26.88	0:00:26	[Frame 1611 at 0:00:26] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/5238783c_f1611.jpg	0	2026-03-21 00:26:05.359515+00
90	8	CAM-A01	90	1790	29.86	0:00:29	[Frame 1790 at 0:00:29] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/7ea8681c_f1790.jpg	0	2026-03-21 00:26:05.386377+00
91	8	CAM-A01	91	1969	32.85	0:00:32	[Frame 1969 at 0:00:32] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/1c75dc1e_f1969.jpg	0	2026-03-21 00:26:05.410711+00
92	8	CAM-A01	92	2148	35.84	0:00:35	[Frame 2148 at 0:00:35] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/a1701bda_f2148.jpg	0	2026-03-21 00:26:05.43586+00
93	8	CAM-A01	93	2327	38.82	0:00:38	[Frame 2327 at 0:00:38] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/37259cdc_f2327.jpg	0	2026-03-21 00:26:05.464574+00
94	8	CAM-A01	94	2506	41.81	0:00:41	[Frame 2506 at 0:00:41] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/404afc96_f2506.jpg	0	2026-03-21 00:26:05.490169+00
95	8	CAM-A01	95	2685	44.79	0:00:44	[Frame 2685 at 0:00:44] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/60660325_f2685.jpg	0	2026-03-21 00:26:05.516122+00
96	8	CAM-A01	96	2864	47.78	0:00:47	[Frame 2864 at 0:00:47] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/3c1780c8_f2864.jpg	0	2026-03-21 00:26:05.540985+00
97	8	CAM-A01	97	3043	50.77	0:00:50	[Frame 3043 at 0:00:50] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/02358390_f3043.jpg	0	2026-03-21 00:26:05.566726+00
98	8	CAM-A01	98	3222	53.75	0:00:53	[Frame 3222 at 0:00:53] — Awaiting Qwen AI analysis (GPU worker not available)	PENDING	frames/CAM-A01/f0af747d_f3222.jpg	0	2026-03-21 00:26:05.590935+00
106	9	CAM-A01	106	1253	20.90	0:00:20	[Frame 1253 at 0:00:20] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/2dabb7f3_f1253.jpg	0	2026-03-21 00:33:57.620811+00
108	9	CAM-A01	108	1611	26.88	0:00:26	[Frame 1611 at 0:00:26] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/8f4c7dce_f1611.jpg	0	2026-03-21 00:33:57.67635+00
110	9	CAM-A01	110	1969	32.85	0:00:32	[Frame 1969 at 0:00:32] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/6e2a9ff4_f1969.jpg	0	2026-03-21 00:33:57.727587+00
112	9	CAM-A01	112	2327	38.82	0:00:38	[Frame 2327 at 0:00:38] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/bcbcb177_f2327.jpg	0	2026-03-21 00:33:57.776598+00
116	9	CAM-A01	116	3043	50.77	0:00:50	[Frame 3043 at 0:00:50] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/b6645c4d_f3043.jpg	0	2026-03-21 00:33:57.875706+00
119	10	CAM-A01	119	179	2.99	0:00:02	[Frame 179 at 0:00:02] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/1ac3d47b_f0179.jpg	0	2026-03-21 00:41:51.580728+00
122	10	CAM-A01	122	716	11.95	0:00:11	[Frame 716 at 0:00:11] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/2e1f0f2b_f0716.jpg	0	2026-03-21 00:41:51.659002+00
125	10	CAM-A01	125	1253	20.90	0:00:20	[Frame 1253 at 0:00:20] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/f7767c57_f1253.jpg	0	2026-03-21 00:41:51.747577+00
128	10	CAM-A01	128	1790	29.86	0:00:29	[Frame 1790 at 0:00:29] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/f4a4e66d_f1790.jpg	0	2026-03-21 00:41:51.833594+00
131	10	CAM-A01	131	2327	38.82	0:00:38	[Frame 2327 at 0:00:38] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/bb9d364c_f2327.jpg	0	2026-03-21 00:41:51.91501+00
134	10	CAM-A01	134	2864	47.78	0:00:47	[Frame 2864 at 0:00:47] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/fb994482_f2864.jpg	0	2026-03-21 00:41:51.994946+00
107	9	CAM-A01	107	1432	23.89	0:00:23	[Frame 1432 at 0:00:23] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/3749b970_f1432.jpg	0	2026-03-21 00:33:57.647822+00
109	9	CAM-A01	109	1790	29.86	0:00:29	[Frame 1790 at 0:00:29] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/123a21ab_f1790.jpg	0	2026-03-21 00:33:57.703061+00
111	9	CAM-A01	111	2148	35.84	0:00:35	[Frame 2148 at 0:00:35] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/53e0b67a_f2148.jpg	0	2026-03-21 00:33:57.752655+00
113	9	CAM-A01	113	2506	41.81	0:00:41	[Frame 2506 at 0:00:41] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/cd7db77d_f2506.jpg	0	2026-03-21 00:33:57.800117+00
114	9	CAM-A01	114	2685	44.79	0:00:44	[Frame 2685 at 0:00:44] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/6a47c32e_f2685.jpg	0	2026-03-21 00:33:57.825337+00
115	9	CAM-A01	115	2864	47.78	0:00:47	[Frame 2864 at 0:00:47] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/61868855_f2864.jpg	0	2026-03-21 00:33:57.851069+00
117	9	CAM-A01	117	3222	53.75	0:00:53	[Frame 3222 at 0:00:53] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/362f88ff_f3222.jpg	0	2026-03-21 00:33:57.900434+00
118	10	CAM-A01	118	0	0.00	0:00:00	[Frame 0 at 0:00:00] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/ad91dd3b_f0000.jpg	0	2026-03-21 00:41:51.529648+00
120	10	CAM-A01	120	358	5.97	0:00:05	[Frame 358 at 0:00:05] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/bd162e37_f0358.jpg	0	2026-03-21 00:41:51.607047+00
121	10	CAM-A01	121	537	8.96	0:00:08	[Frame 537 at 0:00:08] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/6f7d9969_f0537.jpg	0	2026-03-21 00:41:51.633035+00
123	10	CAM-A01	123	895	14.93	0:00:14	[Frame 895 at 0:00:14] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/3793a1fd_f0895.jpg	0	2026-03-21 00:41:51.687547+00
124	10	CAM-A01	124	1074	17.92	0:00:17	[Frame 1074 at 0:00:17] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/a70e981a_f1074.jpg	0	2026-03-21 00:41:51.717684+00
126	10	CAM-A01	126	1432	23.89	0:00:23	[Frame 1432 at 0:00:23] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/e82a1476_f1432.jpg	0	2026-03-21 00:41:51.777305+00
127	10	CAM-A01	127	1611	26.88	0:00:26	[Frame 1611 at 0:00:26] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/e19a122a_f1611.jpg	0	2026-03-21 00:41:51.805859+00
129	10	CAM-A01	129	1969	32.85	0:00:32	[Frame 1969 at 0:00:32] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/5717424c_f1969.jpg	0	2026-03-21 00:41:51.860035+00
130	10	CAM-A01	130	2148	35.84	0:00:35	[Frame 2148 at 0:00:35] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/0f97581a_f2148.jpg	0	2026-03-21 00:41:51.887637+00
132	10	CAM-A01	132	2506	41.81	0:00:41	[Frame 2506 at 0:00:41] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/ee53c2c7_f2506.jpg	0	2026-03-21 00:41:51.940449+00
133	10	CAM-A01	133	2685	44.79	0:00:44	[Frame 2685 at 0:00:44] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/c0d2dd07_f2685.jpg	0	2026-03-21 00:41:51.966383+00
135	10	CAM-A01	135	3043	50.77	0:00:50	[Frame 3043 at 0:00:50] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/be3c78a4_f3043.jpg	0	2026-03-21 00:41:52.02438+00
136	10	CAM-A01	136	3222	53.75	0:00:53	[Frame 3222 at 0:00:53] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/56fca17a_f3222.jpg	0	2026-03-21 00:41:52.054048+00
137	11	CAM-A01	137	0	0.00	0:00:00	[Frame 0 at 0:00:00] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/d69d16bf_f0000.jpg	0	2026-03-21 00:42:19.422484+00
138	11	CAM-A01	138	179	2.99	0:00:02	[Frame 179 at 0:00:02] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/63d00c2b_f0179.jpg	0	2026-03-21 00:42:19.473395+00
139	11	CAM-A01	139	358	5.97	0:00:05	[Frame 358 at 0:00:05] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/4db74721_f0358.jpg	0	2026-03-21 00:42:19.502213+00
140	11	CAM-A01	140	537	8.96	0:00:08	[Frame 537 at 0:00:08] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/7a927073_f0537.jpg	0	2026-03-21 00:42:19.547287+00
141	11	CAM-A01	141	716	11.95	0:00:11	[Frame 716 at 0:00:11] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/94b10b10_f0716.jpg	0	2026-03-21 00:42:19.589611+00
142	11	CAM-A01	142	895	14.93	0:00:14	[Frame 895 at 0:00:14] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/84bd46c4_f0895.jpg	0	2026-03-21 00:42:19.623132+00
143	11	CAM-A01	143	1074	17.92	0:00:17	[Frame 1074 at 0:00:17] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/0bea6cef_f1074.jpg	0	2026-03-21 00:42:19.656737+00
144	11	CAM-A01	144	1253	20.90	0:00:20	[Frame 1253 at 0:00:20] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/61f899df_f1253.jpg	0	2026-03-21 00:42:19.694732+00
145	11	CAM-A01	145	1432	23.89	0:00:23	[Frame 1432 at 0:00:23] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/ab78a17d_f1432.jpg	0	2026-03-21 00:42:19.732756+00
146	11	CAM-A01	146	1611	26.88	0:00:26	[Frame 1611 at 0:00:26] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/5387150a_f1611.jpg	0	2026-03-21 00:42:19.766369+00
147	11	CAM-A01	147	1790	29.86	0:00:29	[Frame 1790 at 0:00:29] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/1c55263e_f1790.jpg	0	2026-03-21 00:42:19.798451+00
148	11	CAM-A01	148	1969	32.85	0:00:32	[Frame 1969 at 0:00:32] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/8fc72edb_f1969.jpg	0	2026-03-21 00:42:19.831333+00
149	11	CAM-A01	149	2148	35.84	0:00:35	[Frame 2148 at 0:00:35] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/d8e93a13_f2148.jpg	0	2026-03-21 00:42:19.860745+00
150	11	CAM-A01	150	2327	38.82	0:00:38	[Frame 2327 at 0:00:38] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/7f69b0a1_f2327.jpg	0	2026-03-21 00:42:19.892427+00
151	11	CAM-A01	151	2506	41.81	0:00:41	[Frame 2506 at 0:00:41] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/39ee6c20_f2506.jpg	0	2026-03-21 00:42:19.922235+00
152	11	CAM-A01	152	2685	44.79	0:00:44	[Frame 2685 at 0:00:44] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/4ba90ad0_f2685.jpg	0	2026-03-21 00:42:19.949966+00
153	11	CAM-A01	153	2864	47.78	0:00:47	[Frame 2864 at 0:00:47] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/3ae12121_f2864.jpg	0	2026-03-21 00:42:19.977579+00
154	11	CAM-A01	154	3043	50.77	0:00:50	[Frame 3043 at 0:00:50] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/1ba63633_f3043.jpg	0	2026-03-21 00:42:20.003628+00
155	11	CAM-A01	155	3222	53.75	0:00:53	[Frame 3222 at 0:00:53] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/0ca3e9d9_f3222.jpg	0	2026-03-21 00:42:20.033809+00
156	13	CAM-A01	156	0	0.00	0:00:00	[0:00:00] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/2a721cbe_f0000.jpg	0	2026-03-21 09:12:47.787672+00
157	13	CAM-A01	157	179	2.99	0:00:02	[0:00:02] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/6a72a556_f0179.jpg	0	2026-03-21 09:12:47.832229+00
158	13	CAM-A01	158	358	5.97	0:00:05	[0:00:05] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/5c0298e4_f0358.jpg	0	2026-03-21 09:12:47.860425+00
159	13	CAM-A01	159	537	8.96	0:00:08	[0:00:08] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/23130203_f0537.jpg	0	2026-03-21 09:12:47.889139+00
160	13	CAM-A01	160	716	11.95	0:00:11	[0:00:11] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/a0395109_f0716.jpg	0	2026-03-21 09:12:47.919678+00
161	13	CAM-A01	161	895	14.93	0:00:14	[0:00:14] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/0e7bcad8_f0895.jpg	0	2026-03-21 09:12:47.950446+00
162	13	CAM-A01	162	1074	17.92	0:00:17	[0:00:17] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/21c37ec5_f1074.jpg	0	2026-03-21 09:12:47.979803+00
163	13	CAM-A01	163	1253	20.90	0:00:20	[0:00:20] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/0b24e9c8_f1253.jpg	0	2026-03-21 09:12:48.007347+00
164	13	CAM-A01	164	1432	23.89	0:00:23	[0:00:23] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/73e08c58_f1432.jpg	0	2026-03-21 09:12:48.038693+00
165	13	CAM-A01	165	1611	26.88	0:00:26	[0:00:26] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/e8b3cb4c_f1611.jpg	0	2026-03-21 09:12:48.070602+00
166	13	CAM-A01	166	1790	29.86	0:00:29	[0:00:29] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/003a5b5f_f1790.jpg	0	2026-03-21 09:12:48.100035+00
167	13	CAM-A01	167	1969	32.85	0:00:32	[0:00:32] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/509edb43_f1969.jpg	0	2026-03-21 09:12:48.129206+00
168	13	CAM-A01	168	2148	35.84	0:00:35	[0:00:35] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/af3821ff_f2148.jpg	0	2026-03-21 09:12:48.171572+00
169	13	CAM-A01	169	2327	38.82	0:00:38	[0:00:38] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/152c6efd_f2327.jpg	0	2026-03-21 09:12:48.216775+00
170	13	CAM-A01	170	2506	41.81	0:00:41	[0:00:41] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/140a8f01_f2506.jpg	0	2026-03-21 09:12:48.271688+00
171	13	CAM-A01	171	2685	44.79	0:00:44	[0:00:44] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/79cc0953_f2685.jpg	0	2026-03-21 09:12:48.310593+00
172	13	CAM-A01	172	2864	47.78	0:00:47	[0:00:47] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/82c0779f_f2864.jpg	0	2026-03-21 09:12:48.350122+00
173	13	CAM-A01	173	3043	50.77	0:00:50	[0:00:50] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/fc377031_f3043.jpg	0	2026-03-21 09:12:48.380997+00
174	13	CAM-A01	174	3222	53.75	0:00:53	[0:00:53] — Start Qwen Service to get AI analysis	PENDING	frames/CAM-A01/dcc8cce7_f3222.jpg	0	2026-03-21 09:12:48.418599+00
\.


--
-- Data for Name: media_files; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.media_files (id, event_id, camera_id, file_type, filename, filepath, size_bytes, mime_type, created_at) FROM stdin;
1	1	CAM-A01	image	33afbaa0_f0000.jpg	frames/CAM-A01/33afbaa0_f0000.jpg	\N	image/jpeg	2026-03-21 00:00:29.456678+00
2	2	CAM-A01	image	b70954d0_f0179.jpg	frames/CAM-A01/b70954d0_f0179.jpg	\N	image/jpeg	2026-03-21 00:00:29.522736+00
3	3	CAM-A01	image	6831c2a2_f0358.jpg	frames/CAM-A01/6831c2a2_f0358.jpg	\N	image/jpeg	2026-03-21 00:00:29.566128+00
4	4	CAM-A01	image	295b46a2_f0537.jpg	frames/CAM-A01/295b46a2_f0537.jpg	\N	image/jpeg	2026-03-21 00:00:29.598327+00
5	5	CAM-A01	image	869f0a31_f0716.jpg	frames/CAM-A01/869f0a31_f0716.jpg	\N	image/jpeg	2026-03-21 00:00:29.625971+00
6	6	CAM-A01	image	19cd461c_f0895.jpg	frames/CAM-A01/19cd461c_f0895.jpg	\N	image/jpeg	2026-03-21 00:00:29.650445+00
7	7	CAM-A01	image	e346cd67_f1074.jpg	frames/CAM-A01/e346cd67_f1074.jpg	\N	image/jpeg	2026-03-21 00:00:29.67605+00
8	8	CAM-A01	image	73917db8_f1253.jpg	frames/CAM-A01/73917db8_f1253.jpg	\N	image/jpeg	2026-03-21 00:00:29.700165+00
9	9	CAM-A01	image	9c355206_f1432.jpg	frames/CAM-A01/9c355206_f1432.jpg	\N	image/jpeg	2026-03-21 00:00:29.724482+00
10	10	CAM-A01	image	1c8cdbc2_f1611.jpg	frames/CAM-A01/1c8cdbc2_f1611.jpg	\N	image/jpeg	2026-03-21 00:00:29.749089+00
11	11	CAM-A01	image	c3a0c3eb_f1790.jpg	frames/CAM-A01/c3a0c3eb_f1790.jpg	\N	image/jpeg	2026-03-21 00:00:29.774923+00
12	12	CAM-A01	image	59bcc44a_f1969.jpg	frames/CAM-A01/59bcc44a_f1969.jpg	\N	image/jpeg	2026-03-21 00:00:29.800329+00
13	13	CAM-A01	image	0be42afd_f2148.jpg	frames/CAM-A01/0be42afd_f2148.jpg	\N	image/jpeg	2026-03-21 00:00:29.826742+00
14	14	CAM-A01	image	3c5f4caf_f2327.jpg	frames/CAM-A01/3c5f4caf_f2327.jpg	\N	image/jpeg	2026-03-21 00:00:29.853924+00
15	15	CAM-A01	image	d55bb818_f2506.jpg	frames/CAM-A01/d55bb818_f2506.jpg	\N	image/jpeg	2026-03-21 00:00:29.880934+00
16	16	CAM-A01	image	d3da19da_f2685.jpg	frames/CAM-A01/d3da19da_f2685.jpg	\N	image/jpeg	2026-03-21 00:00:29.907847+00
17	17	CAM-A01	image	b560cc87_f2864.jpg	frames/CAM-A01/b560cc87_f2864.jpg	\N	image/jpeg	2026-03-21 00:00:29.934901+00
18	18	CAM-A01	image	75e8e8a2_f3043.jpg	frames/CAM-A01/75e8e8a2_f3043.jpg	\N	image/jpeg	2026-03-21 00:00:29.960423+00
19	19	CAM-A01	image	ea65bede_f3222.jpg	frames/CAM-A01/ea65bede_f3222.jpg	\N	image/jpeg	2026-03-21 00:00:29.988231+00
20	30	CAM-A02	image	a44baf0b_f0000.jpg	frames/CAM-A02/a44baf0b_f0000.jpg	\N	image/jpeg	2026-03-21 00:04:41.587916+00
21	31	CAM-A02	image	c0df1551_f0179.jpg	frames/CAM-A02/c0df1551_f0179.jpg	\N	image/jpeg	2026-03-21 00:04:41.648357+00
22	32	CAM-A02	image	48f9ab20_f0358.jpg	frames/CAM-A02/48f9ab20_f0358.jpg	\N	image/jpeg	2026-03-21 00:04:41.697583+00
23	33	CAM-A02	image	5a5586ed_f0537.jpg	frames/CAM-A02/5a5586ed_f0537.jpg	\N	image/jpeg	2026-03-21 00:04:41.732563+00
24	34	CAM-A02	image	31885b91_f0716.jpg	frames/CAM-A02/31885b91_f0716.jpg	\N	image/jpeg	2026-03-21 00:04:41.758091+00
25	35	CAM-A02	image	7fa27a3d_f0895.jpg	frames/CAM-A02/7fa27a3d_f0895.jpg	\N	image/jpeg	2026-03-21 00:04:41.801866+00
26	36	CAM-A02	image	d041ac24_f1074.jpg	frames/CAM-A02/d041ac24_f1074.jpg	\N	image/jpeg	2026-03-21 00:04:41.829386+00
27	37	CAM-A02	image	ca2f766d_f1253.jpg	frames/CAM-A02/ca2f766d_f1253.jpg	\N	image/jpeg	2026-03-21 00:04:41.865439+00
28	38	CAM-A02	image	c4b127b0_f1432.jpg	frames/CAM-A02/c4b127b0_f1432.jpg	\N	image/jpeg	2026-03-21 00:04:41.924169+00
29	39	CAM-A02	image	a492d7ef_f1611.jpg	frames/CAM-A02/a492d7ef_f1611.jpg	\N	image/jpeg	2026-03-21 00:04:42.002911+00
30	40	CAM-A02	image	170e0545_f1790.jpg	frames/CAM-A02/170e0545_f1790.jpg	\N	image/jpeg	2026-03-21 00:04:42.038423+00
31	41	CAM-A02	image	27ba9579_f1969.jpg	frames/CAM-A02/27ba9579_f1969.jpg	\N	image/jpeg	2026-03-21 00:04:42.080909+00
32	42	CAM-A02	image	0f731309_f2148.jpg	frames/CAM-A02/0f731309_f2148.jpg	\N	image/jpeg	2026-03-21 00:04:42.169185+00
33	43	CAM-A02	image	550ad072_f2327.jpg	frames/CAM-A02/550ad072_f2327.jpg	\N	image/jpeg	2026-03-21 00:04:42.229497+00
34	44	CAM-A02	image	7a86b696_f2506.jpg	frames/CAM-A02/7a86b696_f2506.jpg	\N	image/jpeg	2026-03-21 00:04:42.296473+00
35	45	CAM-A02	image	dda94f4d_f2685.jpg	frames/CAM-A02/dda94f4d_f2685.jpg	\N	image/jpeg	2026-03-21 00:04:42.334802+00
36	46	CAM-A02	image	1faa69ce_f2864.jpg	frames/CAM-A02/1faa69ce_f2864.jpg	\N	image/jpeg	2026-03-21 00:04:42.364449+00
37	47	CAM-A02	image	448eb217_f3043.jpg	frames/CAM-A02/448eb217_f3043.jpg	\N	image/jpeg	2026-03-21 00:04:42.395472+00
38	48	CAM-A02	image	a3e4c5cf_f3222.jpg	frames/CAM-A02/a3e4c5cf_f3222.jpg	\N	image/jpeg	2026-03-21 00:04:42.431597+00
39	49	CAM-A02	image	f72f3f7d_f0000.jpg	frames/CAM-A02/f72f3f7d_f0000.jpg	\N	image/jpeg	2026-03-21 00:07:53.684001+00
40	50	CAM-A02	image	3622b9c0_f0179.jpg	frames/CAM-A02/3622b9c0_f0179.jpg	\N	image/jpeg	2026-03-21 00:07:53.711545+00
41	51	CAM-A02	image	7e9582ff_f0358.jpg	frames/CAM-A02/7e9582ff_f0358.jpg	\N	image/jpeg	2026-03-21 00:07:53.747515+00
42	52	CAM-A02	image	cfdc2d80_f0537.jpg	frames/CAM-A02/cfdc2d80_f0537.jpg	\N	image/jpeg	2026-03-21 00:07:53.777476+00
43	53	CAM-A02	image	397ad703_f0716.jpg	frames/CAM-A02/397ad703_f0716.jpg	\N	image/jpeg	2026-03-21 00:07:53.804059+00
44	54	CAM-A02	image	677aa8d0_f0895.jpg	frames/CAM-A02/677aa8d0_f0895.jpg	\N	image/jpeg	2026-03-21 00:07:53.833961+00
45	55	CAM-A02	image	847be0a5_f1074.jpg	frames/CAM-A02/847be0a5_f1074.jpg	\N	image/jpeg	2026-03-21 00:07:53.860591+00
46	56	CAM-A02	image	13df4fd2_f1253.jpg	frames/CAM-A02/13df4fd2_f1253.jpg	\N	image/jpeg	2026-03-21 00:07:53.887565+00
47	57	CAM-A02	image	2311520a_f1432.jpg	frames/CAM-A02/2311520a_f1432.jpg	\N	image/jpeg	2026-03-21 00:07:53.913177+00
48	58	CAM-A02	image	3bba94c7_f1611.jpg	frames/CAM-A02/3bba94c7_f1611.jpg	\N	image/jpeg	2026-03-21 00:07:53.939947+00
49	59	CAM-A02	image	eb4b2704_f1790.jpg	frames/CAM-A02/eb4b2704_f1790.jpg	\N	image/jpeg	2026-03-21 00:07:53.96681+00
50	60	CAM-A02	image	e026a786_f1969.jpg	frames/CAM-A02/e026a786_f1969.jpg	\N	image/jpeg	2026-03-21 00:07:53.995596+00
51	61	CAM-A02	image	71bd7b67_f2148.jpg	frames/CAM-A02/71bd7b67_f2148.jpg	\N	image/jpeg	2026-03-21 00:07:54.02381+00
52	62	CAM-A02	image	79d8754a_f2327.jpg	frames/CAM-A02/79d8754a_f2327.jpg	\N	image/jpeg	2026-03-21 00:07:54.050614+00
53	63	CAM-A02	image	a1322bdf_f2506.jpg	frames/CAM-A02/a1322bdf_f2506.jpg	\N	image/jpeg	2026-03-21 00:07:54.076532+00
54	64	CAM-A02	image	ab2af82c_f2685.jpg	frames/CAM-A02/ab2af82c_f2685.jpg	\N	image/jpeg	2026-03-21 00:07:54.103295+00
55	65	CAM-A02	image	072c2b14_f2864.jpg	frames/CAM-A02/072c2b14_f2864.jpg	\N	image/jpeg	2026-03-21 00:07:54.12948+00
56	66	CAM-A02	image	8f7ba0fc_f3043.jpg	frames/CAM-A02/8f7ba0fc_f3043.jpg	\N	image/jpeg	2026-03-21 00:07:54.156385+00
57	67	CAM-A02	image	68f8fe50_f3222.jpg	frames/CAM-A02/68f8fe50_f3222.jpg	\N	image/jpeg	2026-03-21 00:07:54.183148+00
58	80	CAM-A01	image	16f0a458_f0000.jpg	frames/CAM-A01/16f0a458_f0000.jpg	\N	image/jpeg	2026-03-21 00:26:05.117914+00
59	81	CAM-A01	image	8abfcc8a_f0179.jpg	frames/CAM-A01/8abfcc8a_f0179.jpg	\N	image/jpeg	2026-03-21 00:26:05.153878+00
60	82	CAM-A01	image	e666827b_f0358.jpg	frames/CAM-A01/e666827b_f0358.jpg	\N	image/jpeg	2026-03-21 00:26:05.182872+00
61	83	CAM-A01	image	614bd643_f0537.jpg	frames/CAM-A01/614bd643_f0537.jpg	\N	image/jpeg	2026-03-21 00:26:05.208296+00
62	84	CAM-A01	image	9e414f65_f0716.jpg	frames/CAM-A01/9e414f65_f0716.jpg	\N	image/jpeg	2026-03-21 00:26:05.233125+00
64	86	CAM-A01	image	c1790328_f1074.jpg	frames/CAM-A01/c1790328_f1074.jpg	\N	image/jpeg	2026-03-21 00:26:05.284294+00
66	88	CAM-A01	image	e1133c63_f1432.jpg	frames/CAM-A01/e1133c63_f1432.jpg	\N	image/jpeg	2026-03-21 00:26:05.335323+00
68	90	CAM-A01	image	7ea8681c_f1790.jpg	frames/CAM-A01/7ea8681c_f1790.jpg	\N	image/jpeg	2026-03-21 00:26:05.386377+00
70	92	CAM-A01	image	a1701bda_f2148.jpg	frames/CAM-A01/a1701bda_f2148.jpg	\N	image/jpeg	2026-03-21 00:26:05.43586+00
72	94	CAM-A01	image	404afc96_f2506.jpg	frames/CAM-A01/404afc96_f2506.jpg	\N	image/jpeg	2026-03-21 00:26:05.490169+00
74	96	CAM-A01	image	3c1780c8_f2864.jpg	frames/CAM-A01/3c1780c8_f2864.jpg	\N	image/jpeg	2026-03-21 00:26:05.540985+00
76	98	CAM-A01	image	f0af747d_f3222.jpg	frames/CAM-A01/f0af747d_f3222.jpg	\N	image/jpeg	2026-03-21 00:26:05.590935+00
63	85	CAM-A01	image	47d73686_f0895.jpg	frames/CAM-A01/47d73686_f0895.jpg	\N	image/jpeg	2026-03-21 00:26:05.258681+00
65	87	CAM-A01	image	b70f13c8_f1253.jpg	frames/CAM-A01/b70f13c8_f1253.jpg	\N	image/jpeg	2026-03-21 00:26:05.310273+00
67	89	CAM-A01	image	5238783c_f1611.jpg	frames/CAM-A01/5238783c_f1611.jpg	\N	image/jpeg	2026-03-21 00:26:05.359515+00
69	91	CAM-A01	image	1c75dc1e_f1969.jpg	frames/CAM-A01/1c75dc1e_f1969.jpg	\N	image/jpeg	2026-03-21 00:26:05.410711+00
71	93	CAM-A01	image	37259cdc_f2327.jpg	frames/CAM-A01/37259cdc_f2327.jpg	\N	image/jpeg	2026-03-21 00:26:05.464574+00
73	95	CAM-A01	image	60660325_f2685.jpg	frames/CAM-A01/60660325_f2685.jpg	\N	image/jpeg	2026-03-21 00:26:05.516122+00
75	97	CAM-A01	image	02358390_f3043.jpg	frames/CAM-A01/02358390_f3043.jpg	\N	image/jpeg	2026-03-21 00:26:05.566726+00
77	99	CAM-A01	image	ae77dbec_f0000.jpg	frames/CAM-A01/ae77dbec_f0000.jpg	\N	image/jpeg	2026-03-21 00:33:57.396151+00
78	100	CAM-A01	image	a0cc50fd_f0179.jpg	frames/CAM-A01/a0cc50fd_f0179.jpg	\N	image/jpeg	2026-03-21 00:33:57.450694+00
79	101	CAM-A01	image	4f18c2bd_f0358.jpg	frames/CAM-A01/4f18c2bd_f0358.jpg	\N	image/jpeg	2026-03-21 00:33:57.481374+00
80	102	CAM-A01	image	b7dffd02_f0537.jpg	frames/CAM-A01/b7dffd02_f0537.jpg	\N	image/jpeg	2026-03-21 00:33:57.509686+00
81	103	CAM-A01	image	7cda8198_f0716.jpg	frames/CAM-A01/7cda8198_f0716.jpg	\N	image/jpeg	2026-03-21 00:33:57.539806+00
82	104	CAM-A01	image	fb24f890_f0895.jpg	frames/CAM-A01/fb24f890_f0895.jpg	\N	image/jpeg	2026-03-21 00:33:57.567839+00
83	105	CAM-A01	image	8f1dccaa_f1074.jpg	frames/CAM-A01/8f1dccaa_f1074.jpg	\N	image/jpeg	2026-03-21 00:33:57.595147+00
84	106	CAM-A01	image	2dabb7f3_f1253.jpg	frames/CAM-A01/2dabb7f3_f1253.jpg	\N	image/jpeg	2026-03-21 00:33:57.620811+00
85	107	CAM-A01	image	3749b970_f1432.jpg	frames/CAM-A01/3749b970_f1432.jpg	\N	image/jpeg	2026-03-21 00:33:57.647822+00
86	108	CAM-A01	image	8f4c7dce_f1611.jpg	frames/CAM-A01/8f4c7dce_f1611.jpg	\N	image/jpeg	2026-03-21 00:33:57.67635+00
87	109	CAM-A01	image	123a21ab_f1790.jpg	frames/CAM-A01/123a21ab_f1790.jpg	\N	image/jpeg	2026-03-21 00:33:57.703061+00
88	110	CAM-A01	image	6e2a9ff4_f1969.jpg	frames/CAM-A01/6e2a9ff4_f1969.jpg	\N	image/jpeg	2026-03-21 00:33:57.727587+00
89	111	CAM-A01	image	53e0b67a_f2148.jpg	frames/CAM-A01/53e0b67a_f2148.jpg	\N	image/jpeg	2026-03-21 00:33:57.752655+00
90	112	CAM-A01	image	bcbcb177_f2327.jpg	frames/CAM-A01/bcbcb177_f2327.jpg	\N	image/jpeg	2026-03-21 00:33:57.776598+00
91	113	CAM-A01	image	cd7db77d_f2506.jpg	frames/CAM-A01/cd7db77d_f2506.jpg	\N	image/jpeg	2026-03-21 00:33:57.800117+00
92	114	CAM-A01	image	6a47c32e_f2685.jpg	frames/CAM-A01/6a47c32e_f2685.jpg	\N	image/jpeg	2026-03-21 00:33:57.825337+00
93	115	CAM-A01	image	61868855_f2864.jpg	frames/CAM-A01/61868855_f2864.jpg	\N	image/jpeg	2026-03-21 00:33:57.851069+00
94	116	CAM-A01	image	b6645c4d_f3043.jpg	frames/CAM-A01/b6645c4d_f3043.jpg	\N	image/jpeg	2026-03-21 00:33:57.875706+00
95	117	CAM-A01	image	362f88ff_f3222.jpg	frames/CAM-A01/362f88ff_f3222.jpg	\N	image/jpeg	2026-03-21 00:33:57.900434+00
96	118	CAM-A01	image	ad91dd3b_f0000.jpg	frames/CAM-A01/ad91dd3b_f0000.jpg	\N	image/jpeg	2026-03-21 00:41:51.529648+00
97	119	CAM-A01	image	1ac3d47b_f0179.jpg	frames/CAM-A01/1ac3d47b_f0179.jpg	\N	image/jpeg	2026-03-21 00:41:51.580728+00
98	120	CAM-A01	image	bd162e37_f0358.jpg	frames/CAM-A01/bd162e37_f0358.jpg	\N	image/jpeg	2026-03-21 00:41:51.607047+00
99	121	CAM-A01	image	6f7d9969_f0537.jpg	frames/CAM-A01/6f7d9969_f0537.jpg	\N	image/jpeg	2026-03-21 00:41:51.633035+00
100	122	CAM-A01	image	2e1f0f2b_f0716.jpg	frames/CAM-A01/2e1f0f2b_f0716.jpg	\N	image/jpeg	2026-03-21 00:41:51.659002+00
101	123	CAM-A01	image	3793a1fd_f0895.jpg	frames/CAM-A01/3793a1fd_f0895.jpg	\N	image/jpeg	2026-03-21 00:41:51.687547+00
102	124	CAM-A01	image	a70e981a_f1074.jpg	frames/CAM-A01/a70e981a_f1074.jpg	\N	image/jpeg	2026-03-21 00:41:51.717684+00
103	125	CAM-A01	image	f7767c57_f1253.jpg	frames/CAM-A01/f7767c57_f1253.jpg	\N	image/jpeg	2026-03-21 00:41:51.747577+00
104	126	CAM-A01	image	e82a1476_f1432.jpg	frames/CAM-A01/e82a1476_f1432.jpg	\N	image/jpeg	2026-03-21 00:41:51.777305+00
105	127	CAM-A01	image	e19a122a_f1611.jpg	frames/CAM-A01/e19a122a_f1611.jpg	\N	image/jpeg	2026-03-21 00:41:51.805859+00
106	128	CAM-A01	image	f4a4e66d_f1790.jpg	frames/CAM-A01/f4a4e66d_f1790.jpg	\N	image/jpeg	2026-03-21 00:41:51.833594+00
107	129	CAM-A01	image	5717424c_f1969.jpg	frames/CAM-A01/5717424c_f1969.jpg	\N	image/jpeg	2026-03-21 00:41:51.860035+00
108	130	CAM-A01	image	0f97581a_f2148.jpg	frames/CAM-A01/0f97581a_f2148.jpg	\N	image/jpeg	2026-03-21 00:41:51.887637+00
109	131	CAM-A01	image	bb9d364c_f2327.jpg	frames/CAM-A01/bb9d364c_f2327.jpg	\N	image/jpeg	2026-03-21 00:41:51.91501+00
110	132	CAM-A01	image	ee53c2c7_f2506.jpg	frames/CAM-A01/ee53c2c7_f2506.jpg	\N	image/jpeg	2026-03-21 00:41:51.940449+00
111	133	CAM-A01	image	c0d2dd07_f2685.jpg	frames/CAM-A01/c0d2dd07_f2685.jpg	\N	image/jpeg	2026-03-21 00:41:51.966383+00
112	134	CAM-A01	image	fb994482_f2864.jpg	frames/CAM-A01/fb994482_f2864.jpg	\N	image/jpeg	2026-03-21 00:41:51.994946+00
113	135	CAM-A01	image	be3c78a4_f3043.jpg	frames/CAM-A01/be3c78a4_f3043.jpg	\N	image/jpeg	2026-03-21 00:41:52.02438+00
114	136	CAM-A01	image	56fca17a_f3222.jpg	frames/CAM-A01/56fca17a_f3222.jpg	\N	image/jpeg	2026-03-21 00:41:52.054048+00
115	137	CAM-A01	image	d69d16bf_f0000.jpg	frames/CAM-A01/d69d16bf_f0000.jpg	\N	image/jpeg	2026-03-21 00:42:19.422484+00
116	138	CAM-A01	image	63d00c2b_f0179.jpg	frames/CAM-A01/63d00c2b_f0179.jpg	\N	image/jpeg	2026-03-21 00:42:19.473395+00
117	139	CAM-A01	image	4db74721_f0358.jpg	frames/CAM-A01/4db74721_f0358.jpg	\N	image/jpeg	2026-03-21 00:42:19.502213+00
118	140	CAM-A01	image	7a927073_f0537.jpg	frames/CAM-A01/7a927073_f0537.jpg	\N	image/jpeg	2026-03-21 00:42:19.547287+00
119	141	CAM-A01	image	94b10b10_f0716.jpg	frames/CAM-A01/94b10b10_f0716.jpg	\N	image/jpeg	2026-03-21 00:42:19.589611+00
120	142	CAM-A01	image	84bd46c4_f0895.jpg	frames/CAM-A01/84bd46c4_f0895.jpg	\N	image/jpeg	2026-03-21 00:42:19.623132+00
121	143	CAM-A01	image	0bea6cef_f1074.jpg	frames/CAM-A01/0bea6cef_f1074.jpg	\N	image/jpeg	2026-03-21 00:42:19.656737+00
122	144	CAM-A01	image	61f899df_f1253.jpg	frames/CAM-A01/61f899df_f1253.jpg	\N	image/jpeg	2026-03-21 00:42:19.694732+00
123	145	CAM-A01	image	ab78a17d_f1432.jpg	frames/CAM-A01/ab78a17d_f1432.jpg	\N	image/jpeg	2026-03-21 00:42:19.732756+00
124	146	CAM-A01	image	5387150a_f1611.jpg	frames/CAM-A01/5387150a_f1611.jpg	\N	image/jpeg	2026-03-21 00:42:19.766369+00
125	147	CAM-A01	image	1c55263e_f1790.jpg	frames/CAM-A01/1c55263e_f1790.jpg	\N	image/jpeg	2026-03-21 00:42:19.798451+00
126	148	CAM-A01	image	8fc72edb_f1969.jpg	frames/CAM-A01/8fc72edb_f1969.jpg	\N	image/jpeg	2026-03-21 00:42:19.831333+00
127	149	CAM-A01	image	d8e93a13_f2148.jpg	frames/CAM-A01/d8e93a13_f2148.jpg	\N	image/jpeg	2026-03-21 00:42:19.860745+00
128	150	CAM-A01	image	7f69b0a1_f2327.jpg	frames/CAM-A01/7f69b0a1_f2327.jpg	\N	image/jpeg	2026-03-21 00:42:19.892427+00
129	151	CAM-A01	image	39ee6c20_f2506.jpg	frames/CAM-A01/39ee6c20_f2506.jpg	\N	image/jpeg	2026-03-21 00:42:19.922235+00
130	152	CAM-A01	image	4ba90ad0_f2685.jpg	frames/CAM-A01/4ba90ad0_f2685.jpg	\N	image/jpeg	2026-03-21 00:42:19.949966+00
131	153	CAM-A01	image	3ae12121_f2864.jpg	frames/CAM-A01/3ae12121_f2864.jpg	\N	image/jpeg	2026-03-21 00:42:19.977579+00
132	154	CAM-A01	image	1ba63633_f3043.jpg	frames/CAM-A01/1ba63633_f3043.jpg	\N	image/jpeg	2026-03-21 00:42:20.003628+00
133	155	CAM-A01	image	0ca3e9d9_f3222.jpg	frames/CAM-A01/0ca3e9d9_f3222.jpg	\N	image/jpeg	2026-03-21 00:42:20.033809+00
134	156	CAM-A01	image	2a721cbe_f0000.jpg	frames/CAM-A01/2a721cbe_f0000.jpg	\N	image/jpeg	2026-03-21 09:12:47.787672+00
135	157	CAM-A01	image	6a72a556_f0179.jpg	frames/CAM-A01/6a72a556_f0179.jpg	\N	image/jpeg	2026-03-21 09:12:47.832229+00
136	158	CAM-A01	image	5c0298e4_f0358.jpg	frames/CAM-A01/5c0298e4_f0358.jpg	\N	image/jpeg	2026-03-21 09:12:47.860425+00
137	159	CAM-A01	image	23130203_f0537.jpg	frames/CAM-A01/23130203_f0537.jpg	\N	image/jpeg	2026-03-21 09:12:47.889139+00
138	160	CAM-A01	image	a0395109_f0716.jpg	frames/CAM-A01/a0395109_f0716.jpg	\N	image/jpeg	2026-03-21 09:12:47.919678+00
139	161	CAM-A01	image	0e7bcad8_f0895.jpg	frames/CAM-A01/0e7bcad8_f0895.jpg	\N	image/jpeg	2026-03-21 09:12:47.950446+00
140	162	CAM-A01	image	21c37ec5_f1074.jpg	frames/CAM-A01/21c37ec5_f1074.jpg	\N	image/jpeg	2026-03-21 09:12:47.979803+00
141	163	CAM-A01	image	0b24e9c8_f1253.jpg	frames/CAM-A01/0b24e9c8_f1253.jpg	\N	image/jpeg	2026-03-21 09:12:48.007347+00
142	164	CAM-A01	image	73e08c58_f1432.jpg	frames/CAM-A01/73e08c58_f1432.jpg	\N	image/jpeg	2026-03-21 09:12:48.038693+00
143	165	CAM-A01	image	e8b3cb4c_f1611.jpg	frames/CAM-A01/e8b3cb4c_f1611.jpg	\N	image/jpeg	2026-03-21 09:12:48.070602+00
144	166	CAM-A01	image	003a5b5f_f1790.jpg	frames/CAM-A01/003a5b5f_f1790.jpg	\N	image/jpeg	2026-03-21 09:12:48.100035+00
145	167	CAM-A01	image	509edb43_f1969.jpg	frames/CAM-A01/509edb43_f1969.jpg	\N	image/jpeg	2026-03-21 09:12:48.129206+00
146	168	CAM-A01	image	af3821ff_f2148.jpg	frames/CAM-A01/af3821ff_f2148.jpg	\N	image/jpeg	2026-03-21 09:12:48.171572+00
147	169	CAM-A01	image	152c6efd_f2327.jpg	frames/CAM-A01/152c6efd_f2327.jpg	\N	image/jpeg	2026-03-21 09:12:48.216775+00
148	170	CAM-A01	image	140a8f01_f2506.jpg	frames/CAM-A01/140a8f01_f2506.jpg	\N	image/jpeg	2026-03-21 09:12:48.271688+00
149	171	CAM-A01	image	79cc0953_f2685.jpg	frames/CAM-A01/79cc0953_f2685.jpg	\N	image/jpeg	2026-03-21 09:12:48.310593+00
150	172	CAM-A01	image	82c0779f_f2864.jpg	frames/CAM-A01/82c0779f_f2864.jpg	\N	image/jpeg	2026-03-21 09:12:48.350122+00
151	173	CAM-A01	image	fc377031_f3043.jpg	frames/CAM-A01/fc377031_f3043.jpg	\N	image/jpeg	2026-03-21 09:12:48.380997+00
152	174	CAM-A01	image	dcc8cce7_f3222.jpg	frames/CAM-A01/dcc8cce7_f3222.jpg	\N	image/jpeg	2026-03-21 09:12:48.418599+00
\.


--
-- Data for Name: processes; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.processes (id, code, name, name_th, description, active, created_at) FROM stdin;
1	FORKLIFT-ROLL	Forklift Roll Handling	การเคลื่อนย้ายม้วนวัสดุด้วย Forklift	กระบวนการเคลื่อนย้ายม้วนวัสดุในโกดังด้วย Forklift อย่างปลอดภัย	t	2026-03-21 07:44:52.338496+00
2	PROC-001	Inspection and Clean the Can.	การตรวจสอบคุณภาพกระป๋อง	\N	t	2026-03-21 11:18:04.612635+00
\.


--
-- Data for Name: prompts; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.prompts (id, name, category, content, active, created_at, code, type, type_color, is_system, is_pinned, updated_at, last_test_output, last_test_json) FROM stdin;
7	Custom Prompt	\N		t	2026-03-21 12:52:50.417781+00	P-07	CUSTOM	#64748b	f	f	\N	\N	\N
3	Unsafe Action Detection	\N	Detect all unsafe actions in this video.\nFor each unsafe action:\n- Actor description\n- Exact action performed\n- Risk level (Low/Med/High/Critical)\n- Body zone involved\n- Recommended countermeasure	t	2026-03-21 12:52:50.417781+00	P-03	UNSAFE-ACT	#e53e3e	t	f	\N	\N	\N
4	PPE Compliance Check	\N	Verify PPE compliance for each visible worker.\nCheck for: helmet, gloves, face shield, safety shoes, high-vis vest.\nFor each worker: position, PPE present, PPE missing, severity of violation.	t	2026-03-21 12:52:50.417781+00	P-04	PPE	#16a34a	t	f	\N	\N	\N
5	Near-Miss Explanation	\N	Identify near-miss situations.\nFor each near-miss:\n1. Who is involved\n2. Dangerous interaction occurred\n3. Why it is risky\n4. Severity if actual incident\n5. Prevention recommendations	t	2026-03-21 12:52:50.417781+00	P-05	NEAR-MISS	#d97706	t	f	\N	\N	\N
6	Generate Safety Rule	\N	Generate safety rules from observed risks.\nSeparate into:\n- Unsafe Actions (operator behavior rules)\n- Unsafe Conditions (environment/equipment rules)\n- Preventive Rules\n- Supervisor Recommendations	t	2026-03-21 12:52:50.417781+00	P-06	RULE-GEN	#7c3aed	t	f	\N	\N	\N
2	SOP Compliance Check	\N	Compare observed actions with the defined SOP.\nIdentify:\n1. Steps followed correctly\n2. Steps skipped or missed\n3. Out-of-order actions\n4. Safety impact of each deviation\n5. Overall compliance score (0-100%)	t	2026-03-21 12:52:50.417781+00	P-02	SOP	#0891b2	t	f	\N	\N	\N
1	General Safety Monitoring	\N	{\n  "operation": {\n    "name": "Quality Control Station – Can Inspection",\n    "description": "การตรวจสอบคุณภาพกระป๋องด้วยสายตาก่อนส่งต่อกระบวนการถัดไปผ่านสายพานลำเลียง",\n    "roles": {\n      "Worker1": "หยิบกระป๋อง ตรวจสอบด้วยสายตา วางกระป๋องดีลงบน conveyor วางกระป๋องเสียลง NG tray",\n      "Worker2": "หยิบกระป๋องออกจาก conveyor เช็ดทุกด้าน แพ็คใส่กล่อง Good"\n    },\n    "ppe_specifications": {\n      "helmet": {\n        "required": true,\n        "acceptable_types": [\n          "หมวก safety helmet มาตรฐาน",\n          "หมวก cap / แก๊ป"\n        ],\n        "not_acceptable": [\n          "ไม่สวมหมวกเลย"\n        ],\n        "how_to_identify": "สวมอยู่บนศีรษะ ไม่ว่าจะเป็นแบบใดก็ถือว่าผ่าน — ผิดเฉพาะกรณีไม่สวม"\n      },\n      "safety_shoes": {\n        "required": true,\n        "acceptable_types": [\n          "รองเท้านิรภัยหัวเหล็ก EN ISO 20345",\n          "รองเท้าหัวเหล็กทั่วไป"\n        ],\n        "not_acceptable": [\n          "รองเท้าแตะ",\n          "รองเท้าผ้าใบธรรมดา",\n          "รองเท้าหนังไม่มีหัวเหล็ก",\n          "เท้าเปล่า"\n        ],\n        "how_to_identify": "รองเท้าหุ้มส้น มีหัวแข็ง ดูหนาและแข็งแรง"\n      },\n      "gloves": {\n        "required": true,\n        "acceptable_types": [\n          "ถุงมือยาง / latex",\n          "ถุงมือผ้า",\n          "ถุงมือ nitrile",\n          "ถุงมือหนัง"\n        ],\n        "not_acceptable": [\n          "ไม่สวมถุงมือเลย"\n        ],\n        "how_to_identify": "มีวัสดุหุ้มมือ ไม่ว่าชนิดใด — ผิดเฉพาะกรณีไม่สวม"\n      },\n      "mask": {\n        "required": true,\n        "acceptable_types": [\n          "หน้ากากอนามัย",\n          "N95",\n          "หน้ากากผ้า"\n        ],\n        "not_acceptable": [\n          "ดึงหน้ากากลงคาง",\n          "แขวนหน้ากากที่หู",\n          "ไม่สวมเลย"\n        ],\n        "how_to_identify": "หน้ากากต้องปิดจมูกและปากพร้อมกัน"\n      },\n      "safety_glasses": {\n        "required": false,\n        "note": "ต้องการเฉพาะเมื่อใช้สารเคมีทำความสะอาด"\n      },\n      "safety_vest": {\n        "required": false,\n        "note": "ไม่จำเป็นในสถานีนี้"\n      }\n    },\n    "sop_steps": [\n      {\n        "step": 1,\n        "title": "เตรียมพื้นที่ทำงาน",\n        "skippable": false,\n        "detail": "ตรวจสอบ NG tray กล่อง Good และ conveyor ให้อยู่ในตำแหน่ง ตรวจสอบว่า conveyor ทำงานได้"\n      },\n      {\n        "step": 2,\n        "title": "หยิบกระป๋อง",\n        "skippable": false,\n        "detail": "Worker1 หยิบกระป๋องทีละใบจากกล่องวัตถุดิบ จับเบาๆ เพื่อไม่ให้บุบ"\n      },\n      {\n        "step": 3,\n        "title": "ตรวจสอบด้วยสายตา",\n        "skippable": false,\n        "critical": true,\n        "detail": "ตรวจสอบทุกด้านของกระป๋องภายใต้แสงที่เพียงพอ ตรวจหารอยบุบ สนิม การเสียรูป การปนเปื้อน"\n      },\n      {\n        "step": 4,\n        "title": "คัดแยกกระป๋อง",\n        "skippable": false,\n        "detail": "กระป๋องเสีย → NG tray เท่านั้น กระป๋องดี → วางราบบน conveyor ในตำแหน่งที่กำหนด",\n        "hazard": "Conveyor หนีบมือ",\n        "hazard_severity": "HIGH"\n      },\n      {\n        "step": 5,\n        "title": "สแกนด้วย AI camera",\n        "skippable": false,\n        "detail": "conveyor เลื่อนกระป๋องผ่านกล้อง AI เพื่อตรวจสอบอัตโนมัติ"\n      },\n      {\n        "step": 6,\n        "title": "หยิบกระป๋องออกจาก conveyor",\n        "skippable": false,\n        "critical": true,\n        "detail": "Worker2 หยิบกระป๋องที่ออกมาพ้นสายพานแล้ว หรือรอให้ conveyor หยุดก่อน — การหยิบกระป๋องที่ปลาย conveyor ในตำแหน่งรับของที่กำหนดถือเป็นการทำงานปกติ ผิดเฉพาะกรณีที่มือเข้าไปใน belt area ที่กำลังเคลื่อนที่",\n        "hazard": "Conveyor หนีบมือ",\n        "hazard_severity": "HIGH"\n      },\n      {\n        "step": 7,\n        "title": "เช็ดกระป๋อง",\n        "skippable": false,\n        "detail": "เช็ดทุกด้าน (บน ข้าง ล่าง) ด้วยผ้าสะอาดก่อนแพ็ค",\n        "hazard": "กระป๋องหล่น",\n        "hazard_severity": "MEDIUM"\n      },\n      {\n        "step": 8,\n        "title": "แพ็คใส่กล่อง Good",\n        "skippable": false,\n        "detail": "วางกระป๋องเรียบร้อยในกล่อง Good ห้ามวางเกินความสูงที่กำหนด"\n      }\n    ],\n    "inspection_criteria": {\n      "purpose": "เกณฑ์ตัดสินมาตรฐานสำหรับ Worker1 ในการคัดแยกกระป๋อง Good vs NG",\n      "defect_types": {\n        "dent": {\n          "name": "รอยบุบ",\n          "pass": "รอยบุบเล็กน้อยที่ไม่กระทบรูปทรงโดยรวม ขนาด < 3 mm และไม่อยู่บริเวณขอบหรือฝากระป๋อง",\n          "ng": "รอยบุบลึกหรือกว้าง >= 3 mm, รอยบุบบริเวณขอบหรือฝา, รอยบุบที่ทำให้กระป๋องเสียรูปทรง",\n          "severity": "HIGH"\n        },\n        "rust": {\n          "name": "สนิม",\n          "pass": "ไม่มีสนิมใดๆ",\n          "ng": "พบจุดสนิมหรือคราบสีน้ำตาล/แดงใดๆ บนผิวกระป๋อง ไม่ว่าขนาดเล็กเพียงใด",\n          "severity": "HIGH"\n        },\n        "deformation": {\n          "name": "การเสียรูป",\n          "pass": "กระป๋องทรงกระบอกตรง ปิดฝาได้สนิท",\n          "ng": "กระป๋องบิดเบี้ยว บวม โป่ง หรือฝาปิดไม่สนิท",\n          "severity": "CRITICAL"\n        },\n        "contamination": {\n          "name": "การปนเปื้อน",\n          "pass": "ผิวกระป๋องสะอาด ไม่มีสิ่งแปลกปลอม",\n          "ng": "พบคราบน้ำมัน สารเคมี สิ่งสกปรก หรือวัตถุแปลกปลอมติดผิวกระป๋อง",\n          "severity": "HIGH"\n        },\n        "scratch": {\n          "name": "รอยขีดข่วน",\n          "pass": "รอยขีดตื้นที่ไม่ทะลุผิวเคลือบ",\n          "ng": "รอยขีดที่ทะลุผิวเคลือบจนเห็นเนื้อโลหะ หรือรอยยาวต่อเนื่อง > 10 mm",\n          "severity": "MEDIUM"\n        },\n        "label_defect": {\n          "name": "ฉลาก/พิมพ์ผิดปกติ",\n          "pass": "ตัวอักษรและโลโก้ชัดเจน ไม่เบี้ยว",\n          "ng": "ฉลากเบี้ยว ลอก หรือตัวอักษรไม่ชัดเจน",\n          "severity": "MEDIUM"\n        },\n        "opening": {\n          "name": "ฝา/ช่องเปิด",\n          "pass": "ฝาอยู่ในตำแหน่งปกติ ไม่มีการเปิดบางส่วน",\n          "ng": "ฝาเปิดอยู่บางส่วน ฝาหลุด หรือซีลขาด",\n          "severity": "CRITICAL"\n        }\n      },\n      "inspection_method": [\n        "หมุนกระป๋อง 360° เพื่อตรวจทุกด้าน",\n        "ตรวจด้านบน (ฝา) และด้านล่าง (ก้น) ด้วย",\n        "ตรวจภายใต้แสงสว่างที่เพียงพอเสมอ",\n        "หากสงสัยให้จัดเป็น NG ก่อน แจ้ง Supervisor ตรวจซ้ำ"\n      ],\n      "ng_rate_threshold": {\n        "warning": "NG > 10% ใน 1 ชั่วโมง → แจ้ง Supervisor ทันที",\n        "stop_line": "NG > 20% ใน 1 ชั่วโมง → หยุดสายการผลิต รอการตรวจสอบจาก Supervisor",\n        "warning_severity": "MEDIUM",\n        "stop_line_severity": "HIGH"\n      }\n    },\n    "step_sequence_rules": {\n      "must_follow_order": true,\n      "critical_steps": [\n        3,\n        6\n      ],\n      "skip_severity": {\n        "step_3": "MEDIUM — ข้ามการตรวจสอบด้วยสายตา กระป๋องเสียอาจผ่านไปสายพาน",\n        "step_6": "CRITICAL — หยิบกระป๋องขณะสายพานยังวิ่ง เสี่ยงมือติดสายพาน",\n        "step_7": "MEDIUM — ไม่เช็ดกระป๋อง คุณภาพสินค้าต่ำลง",\n        "other_steps": "LOW — เบี่ยงเบนจาก SOP เล็กน้อย"\n      },\n      "out_of_order_severity": "MEDIUM",\n      "rushing_signs": [\n        "Worker1 วางกระป๋องลง conveyor โดยไม่หยุดตรวจสอบ",\n        "Worker2 หยิบกระป๋องออกก่อนที่จะออกจากสายพาน",\n        "ข้ามขั้นตอนเช็ดกระป๋องเพื่อเร่งความเร็ว"\n      ]\n    },\n    "personnel_management": {\n      "authorized_roles": {\n        "Worker1": {\n          "zone_access": "เต็มพื้นที่",\n          "ppe_required": "ครบทุกชิ้น"\n        },\n        "Worker2": {\n          "zone_access": "เต็มพื้นที่",\n          "ppe_required": "ครบทุกชิ้น"\n        },\n        "Supervisor": {\n          "zone_access": "เข้าได้ตรวจสอบ ห้ามแทรกแซงการทำงาน",\n          "ppe_required": "รองเท้านิรภัยและหมวกอย่างน้อย",\n          "max_duration": "ไม่จำกัด",\n          "severity_if_no_ppe": "MEDIUM"\n        },\n        "Maintenance": {\n          "zone_access": "เข้าได้เฉพาะเมื่อ conveyor หยุดและมี Work Permit",\n          "ppe_required": "ครบทุกชิ้นตามงาน",\n          "severity_if_enter_during_operation": "HIGH"\n        }\n      },\n      "cross_zone_worker": {\n        "definition": "พนักงานจาก zone อื่นเข้ามาแจ้งงานหรือส่งของ",\n        "allowed": true,\n        "conditions": [\n          "ต้องอยู่นอก boundary line ของสถานีทำงาน",\n          "ต้องสวมรองเท้านิรภัยอย่างน้อย",\n          "ห้ามสัมผัสกระป๋องหรืออุปกรณ์",\n          "ระยะเวลาไม่เกิน 2 นาที",\n          "ห้ามส่งอาหาร เครื่องดื่ม หรือสิ่งของส่วนตัวเข้ามาในพื้นที่ปฏิบัติงาน"\n        ],\n        "severity_if_violate": "MEDIUM"\n      },\n      "unauthorized_person": {\n        "definition": "บุคคลที่ไม่มีธุระในพื้นที่ เช่น บุคคลภายนอก ผู้เยี่ยมชมที่ไม่มี escort",\n        "allowed": false,\n        "immediate_response": [\n          "Worker หยุดงานทันที",\n          "แจ้งให้บุคคลออกจากพื้นที่",\n          "แจ้ง Supervisor ทันที",\n          "กลับทำงานเมื่อพื้นที่ปลอดภัยแล้วเท่านั้น"\n        ],\n        "severity": "LOW"\n      },\n      "person_count_alert": {\n        "normal": 2,\n        "alert_if_more_than": 3,\n        "alert_severity": "MEDIUM"\n      }\n    },\n    "incident_types": {\n      "near_miss": {\n        "definition": "เหตุการณ์ที่เกือบเกิดอุบัติเหตุแต่ไม่มีการบาดเจ็บ",\n        "examples": [\n          "มือเกือบโดน conveyor แต่ดึงออกทัน",\n          "กระป๋องเกือบตกแต่รับทัน",\n          "สะดุดแต่ไม่ล้ม",\n          "กระป๋องเกือบหล่นใส่เท้า"\n        ],\n        "severity": "HIGH",\n        "required_action": "หยุดงาน รายงาน Supervisor ทันที บันทึก Near-Miss Report"\n      },\n      "property_damage": {\n        "definition": "อุปกรณ์หรือสินค้าเสียหาย",\n        "examples": [\n          "กระป๋องตกพื้น",\n          "กล่อง Good ล้ม",\n          "NG tray ล้น"\n        ],\n        "severity": "CRITICAL",\n        "required_action": "หยุดงาน เก็บของที่ตก แจ้ง Supervisor"\n      },\n      "minor_injury": {\n        "definition": "บาดเจ็บเล็กน้อย",\n        "examples": [\n          "บาดมือจากขอบกระป๋อง",\n          "ของตกใส่เท้า",\n          "ลื่นล้มเล็กน้อย"\n        ],\n        "severity": "HIGH",\n        "required_action": "หยุดงานทันที ปฐมพยาบาล แจ้ง Supervisor บันทึก Incident Report"\n      },\n      "major_injury": {\n        "definition": "บาดเจ็บสาหัส",\n        "examples": [\n          "มือติด conveyor",\n          "ล้มศีรษะกระแทก",\n          "หมดสติ"\n        ],\n        "severity": "CRITICAL",\n        "required_action": [\n          "กดปุ่ม Emergency Stop ทันที",\n          "โทร 1669 หรือหน่วยฉุกเฉินโรงงาน",\n          "ห้ามเคลื่อนย้ายผู้บาดเจ็บจนกว่าทีมแพทย์จะมาถึง",\n          "แจ้ง Supervisor และ Safety Officer ทันที",\n          "ห้ามเดินเครื่องจนกว่าจะได้รับอนุญาต"\n        ]\n      }\n    },\n    "hygiene_rules": {\n      "purpose": "ป้องกันการปนเปื้อนในผลิตภัณฑ์",\n      "rules": [\n        "ห้ามสัมผัสหน้า ผม หู จมูก ปาก ขณะสวมถุงมือที่ใช้จับกระป๋อง",\n        "หากสัมผัสหน้า ต้องเปลี่ยนถุงมือใหม่ก่อนหยิบกระป๋องต่อ",\n        "กระป๋องที่ตกพื้นถือว่าเป็น NG ต้องใส่ NG tray เสมอ ห้ามหยิบขึ้นมาใช้",\n        "ถุงมือขาดหรือสกปรกต้องเปลี่ยนทันที",\n        "ห้ามรับประทานอาหารหรือดื่มน้ำในพื้นที่ทำงาน",\n        "Worker2 ต้องเช็ดกระป๋องครบทุกด้าน (บน ข้าง ล่าง) ห้ามข้ามด้านใดด้านหนึ่ง",\n        "ห้ามรับอาหาร เครื่องดื่ม หรือสิ่งของส่วนตัวจากบุคคลภายนอกขณะปฏิบัติงานในพื้นที่"\n      ],\n      "violation_severity": "MEDIUM"\n    },\n    "ergonomics_rules": {\n      "purpose": "ป้องกันการบาดเจ็บจากการทำงานซ้ำๆ และท่าทางที่ไม่ถูกต้อง",\n      "normal_posture_note": "การก้มตัวเล็กน้อยเพื่อหยิบกระป๋องเป็นเรื่องปกติของงานนี้ ไม่ต้อง flag",\n      "flag_only_when": [\n        "ก้มหลังอย่างรุนแรง (หลังขนานพื้น) ซ้ำๆ ติดต่อกันหลายครั้ง",\n        "บิดเอวขณะถือกระป๋อง",\n        "แสดงอาการเจ็บปวดชัดเจน เช่น จับหลัง หยุดพักบ่อยผิดปกติ",\n        "ท่าทางแย่ลงเรื่อยๆ เห็นได้ชัดตลอดวิดีโอ"\n      ],\n      "do_not_flag": [\n        "การก้มเล็กน้อยเพื่อหยิบกระป๋อง 1-2 ครั้ง",\n        "ท่าทางปกติของงาน QC",\n        "การเอื้อมมือไปข้างหน้าในระยะสั้น"\n      ],\n      "severity_guide": {\n        "severe_repeated_bending": "LOW",\n        "twisting_with_load": "MEDIUM",\n        "visible_pain_signs": "MEDIUM"\n      }\n    },\n    "behavior_rules": {\n      "focus_requirements": [\n        "ห้ามใช้โทรศัพท์มือถือขณะปฏิบัติงาน",\n        "ห้ามคุยกันในลักษณะที่เสียสมาธิจากการตรวจสอบ",\n        "ห้ามฟังเพลงหรือสวมหูฟังขณะทำงาน"\n      ],\n      "behavior_violations": {\n        "phone_use": {\n          "severity": "MEDIUM",\n          "description": "ใช้โทรศัพท์ขณะทำงาน"\n        },\n        "distracted_talk": {\n          "severity": "LOW",\n          "description": "คุยกันเกินความจำเป็น"\n        },\n        "rushing": {\n          "severity": "HIGH",\n          "description": "ทำงานเร็วเกินจนข้ามขั้นตอนตรวจ"\n        },\n        "fatigue_visible": {\n          "severity": "LOW",\n          "description": "แสดงอาการเมื่อยล้าชัดเจน"\n        }\n      }\n    },\n    "conveyor_rules": [\n      "ห้ามเอื้อมมือเข้าไปใน conveyor ที่กำลังวิ่ง",\n      "วางกระป๋องในตำแหน่งและทิศทางที่กำหนดบน conveyor เท่านั้น",\n      "หาก conveyor ติดขัด ให้หยุดเครื่องก่อนแก้ไขเสมอ",\n      "กระป๋องที่สะสมบน conveyor มากเกินไปต้องรายงาน Supervisor",\n      "ห้ามวางสิ่งของอื่นบน conveyor นอกจากกระป๋องที่ผ่านการตรวจแล้ว",\n      "ห้าม Worker1/Worker2 ปรับ ซ่อม หรือถอดชิ้นส่วนสายพานเอง — ให้หยุดเครื่อง รายงาน Supervisor และรอ Maintenance ดำเนินการ"\n    ],\n    "prohibited_actions": [\n      "เอื้อมมือเข้า conveyor ที่กำลังวิ่ง (CRITICAL)",\n      "หยิบกระป๋องขณะ conveyor ยังทำงาน (CRITICAL)",\n      "ใส่กระป๋อง NG ลงกล่อง Good (HIGH)",\n      "ข้ามขั้นตอนการตรวจสอบด้วยสายตา (HIGH)",\n      "วางกระป๋องที่ตกพื้นกลับเข้า Good (MEDIUM)",\n      "ใช้โทรศัพท์ขณะปฏิบัติงาน (MEDIUM)",\n      "บุคคลที่ไม่เกี่ยวข้องเข้าพื้นที่โดยไม่มี escort (LOW)",\n      "ทำงานโดยไม่สวม PPE ครบ (MEDIUM)",\n      "วางของที่ไม่เกี่ยวข้องกับงานไว้ในพื้นที่ทำงาน (MEDIUM)",\n      "รับอาหารหรือเครื่องดื่มจากบุคคลภายนอกในพื้นที่ทำงาน (MEDIUM)",\n      "Worker ปรับหรือซ่อมสายพานด้วยตนเองโดยไม่มี Maintenance (HIGH)"\n    ],\n    "unsafe_conditions": [\n      "พื้นเปียกหรือลื่น",\n      "กระป๋องกระจายบนพื้น (เสี่ยงสะดุด/ลื่น)",\n      "แสงสว่างไม่เพียงพอสำหรับการตรวจสอบด้วยสายตา",\n      "conveyor ขัดข้อง ติดขัด หรือวิ่งเร็วผิดปกติ",\n      "NG tray เต็มเกินไป (เสี่ยงล้น)",\n      "พื้นที่รก ไม่เป็นระเบียบ (5S ไม่ผ่าน)",\n      "มีสิ่งของที่ไม่เกี่ยวข้องกับงาน (เช่น อาหาร เครื่องดื่ม ของส่วนตัว) วางในพื้นที่ทำงาน"\n    ],\n    "safe_practices": [\n      "รักษาพื้นที่ทำงานให้สะอาดและเป็นระเบียบ (5S)",\n      "รายงานความผิดปกติของ conveyor ต่อ Supervisor ทันที",\n      "ไม่เร่งรีบตรวจสอบ — คุณภาพสำคัญกว่าความเร็ว",\n      "เปลี่ยนถุงมือเมื่อขาดหรือสกปรก",\n      "บันทึก Near-Miss ทุกครั้งแม้ไม่มีการบาดเจ็บ"\n    ]\n  }\n}	t	2026-03-21 12:52:50.417781+00	P-01	SAFETY	#1d6ef5	t	f	2026-03-22 10:34:40.185588+00	Frame 1 [0:00:00 – 0:00:05]:\n### Frame Analysis:\n\n#### Frame 1:\n- **Scene**: Two workers are working at a quality control station.\n- **Workers**: Both workers are wearing gloves, masks, and caps.\n- **Tools**: Workers are using a machine to inspect can lids.\n- **Environment**: The workspace is clean with clear labels for "GOOD" and "NG" trays.\n- **Procedure**:\n  - **Step 1**: Workers are preparing the work area by ensuring the conveyor, NG tray, and GOOD tray are in place.\n  - **Step 2**: Worker 1 picks up cans and inspects them visually.\n  - **Step 3**: Worker 1 places good cans on the conveyor.\n  - **Step 4**: The conveyor scans the cans through an AI camera.\n  - **Step 5**: Worker 2 picks up cans from the conveyor.\n  - **Step 6**: Worker 2 cleans the cans thoroughly.\n  - **Step 7**: Worker 2 packs the cleaned cans into the GOOD tray.\n\n#### Frame 2:\n- **Scene**: Similar setup as Frame 1.\n- **Workers**: Workers are still wearing gloves, masks, and caps.\n- **Tools**: Workers are using a machine to inspect can lids.\n- **Environment**: The workspace is clean with clear labels for "GOOD" and "NG" trays.\n- **Procedure**:\n  - **Step 1**: Workers are preparing the work area by ensuring the conveyor, NG\n\nFrame 2 [0:00:08 – 0:00:14]:\n### Frame Analysis:\n\n#### Frame 1:\n- **Scene**: Workers are inspecting cans on a conveyor.\n- **Workers**: Two workers wearing gloves, masks, and caps.\n- **Tools**: Conveyor system with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor\n\nFrame 3 [0:00:17 – 0:00:23]:\n### Frame Analysis:\n\n#### Frame 1:\n- **Scene**: Workers are inspecting cans on a conveyor.\n- **Workers**: Two workers wearing gloves, masks, and caps.\n- **Tools**: Conveyor, conveyor belt, conveyor belt with a conveyor belt system.\n- **Environment**: Clean workspace with clear instructions and materials.\n\n#### Frame 2:\n- **Scene**: Workers are handling cans on a conveyor.\n- **Workers**: Two workers wearing gloves, masks, and caps.\n- **Tools**: Conveyor, conveyor belt, conveyor belt with a conveyor belt system.\n- **Environment**: Clean workspace with clear instructions and materials.\n\n### Comparison with SOP:\n\n#### Compliance with SOP:\n- **Step 1**: Workers are preparing the work area, which is consistent with the SOP.\n- **Step 2**: Workers are picking cans from the raw material box, which is consistent with the SOP.\n- **Step 3**: Workers are inspecting cans by eye, which is consistent with the SOP.\n- **Step 4**: Workers are placing good cans on the conveyor, which is consistent with the SOP.\n- **Step 5**: Workers are scanning cans through an AI camera, which is consistent with the SOP.\n- **Step 6**: Workers are picking cans from the conveyor, which is consistent with the SOP.\n- **Step 7**: Workers are cleaning cans, which is consistent with the SOP.\n- **Step 8**: Workers are packing good cans into boxes, which is consistent with\n\nFrame 4 [0:00:26 – 0:00:32]:\n### Frame Analysis:\n\n#### Frame 1:\n- **Scene**: Workers are inspecting cans on a production line.\n- **Workers**: Two workers wearing gloves, masks, and caps.\n- **Tools**: Conveyor belt, conveyor belt control panel, NG tray, Good tray, and a scale.\n- **Environment**: Clean and organized workspace with clear signage indicating 'GOOD' and 'NG'.\n\n#### Frame 2:\n- **Scene**: Workers continue the inspection process.\n- **Workers**: Workers are handling cans, checking them visually, and placing good cans on the conveyor while rejecting bad ones into the NG tray.\n- **Tools**: Same as Frame 1.\n- **Environment**: Similar clean and organized workspace.\n\n### Comparison with SOP:\n\n#### Compliance with SOP:\n- **Step 1**: Workers are preparing the work area, which is consistent with the SOP.\n- **Step 2**: Workers are picking cans one by one, which aligns with the SOP.\n- **Step 3**: Workers are visually inspecting the cans, which matches the SOP.\n- **Step 4**: Workers are placing good cans on the conveyor, which is consistent with the SOP.\n- **Step 5**: Workers are scanning the cans through an AI camera, which is also aligned with the SOP.\n- **Step 6**: Workers are removing cans from the conveyor, which is consistent with the SOP.\n- **Step 7**: Workers are cleaning the cans, which is consistent with the SOP.\n- **\n\nFrame 5 [0:00:35 – 0:00:41]:\n### Frame Analysis:\n\n#### Frame 1:\n- **Worker 1** is holding a can and inspecting it with his eyes.\n- **Worker 2** is holding another can and appears to be preparing to inspect it.\n- **Conveyor belt** is visible with some cans on it.\n- **NG tray** and **Good tray** boxes are present on the table.\n- **Safety glasses** are visible on the table, but **Worker 1** is not wearing them.\n- **Safety shoes** are visible, but **Worker 2** is not wearing them.\n- **Gloves** are visible, but **Worker 1** is not wearing them.\n- **Mask** is visible, but **Worker 1** is not wearing it.\n- **Cap** is visible, but **Worker 1** is not wearing it.\n\n#### Frame 2:\n- **Worker 1** is placing a can on the conveyor belt.\n- **Worker 2** is picking up a can from the conveyor belt.\n- **Conveyor belt** is moving, and **Worker 2** is handling the can carefully.\n- **Safety glasses** are visible on the table, but **Worker 2** is not wearing them.\n- **Safety shoes** are visible, but **Worker 2** is not wearing them.\n- **Gloves** are visible, but **Worker 2** is not wearing them.\n- **Mask** is visible, but\n\nFrame 6 [0:00:44 – 0:00:50]:\n### Frame Analysis:\n\n#### Frame 1:\n- **Scene**: Workers are inspecting cans on a conveyor.\n- **Workers**: Two workers wearing gloves, masks, and caps.\n- **Equipment**: A conveyor system with a quality control station.\n- **Objects**: Cans on conveyor, NG tray, Good tray, and a machine for quality inspection.\n\n#### Frame 2:\n- **Scene**: Workers continue inspecting cans.\n- **Workers**: Workers are handling cans and placing them on the conveyor.\n- **Equipment**: Same conveyor system with a quality control station.\n- **Objects**: Cans on conveyor, NG tray, Good tray, and a machine for quality inspection.\n\n### Comparison with SOP:\n\n#### Compliance with SOP:\n- **Step 1**: Workers are preparing the work area by ensuring the NG tray, Good tray, and conveyor are in place.\n- **Step 2**: Workers are picking cans one by one from the raw material box and holding them gently without damaging them.\n- **Step 3**: Workers are checking the cans under the light to ensure there are no defects. This step is critical and requires careful inspection.\n- **Step 4**: Workers are placing good cans on the conveyor in the designated position. This step involves handling the conveyor carefully to avoid injuries.\n- **Step 5**: The conveyor scans the cans using an AI camera to check them automatically. This step is crucial for quality assurance.\n- **Step 6**: Workers are picking cans from the conveyor\n\nFrame 7 [0:00:53 – 0:00:53]:\n### Frame Analysis:\n\n#### Frame 1:\n- **Scene**: Workers are inspecting cans on a conveyor.\n- **Workers**: Two workers wearing gloves, masks, and caps.\n- **Tools**: Conveyor system with a conveyor belt.\n- **Environment**: Clean workspace with clear signage indicating 'GOOD' and 'NG' trays.\n\n#### Frame 2:\n- **Scene**: Workers continue the inspection process.\n- **Workers**: Workers are handling cans and placing them on the conveyor.\n- **Tools**: Conveyor system with a conveyor belt.\n- **Environment**: Clean workspace with clear signage indicating 'GOOD' and 'NG' trays.\n\n### Comparison with SOP:\n\n#### Compliance with SOP:\n- **Step 1**: Workers are preparing the work area, which is consistent with the SOP.\n- **Step 2**: Workers are picking cans from the raw material box, which aligns with the SOP.\n- **Step 3**: Workers are checking the cans visually, which matches the SOP requirement of using the eye for inspection.\n- **Step 4**: The conveyor system is used to move the cans, which is consistent with the SOP.\n- **Step 5**: The conveyor system scans the cans through an AI camera, which aligns with the SOP.\n- **Step 6**: Workers are removing cans from the conveyor, which is consistent with the SOP.\n- **Step 7**: Workers are cleaning the cans, which is consistent with the SOP.\n- **Step 8**: Workers are packing	{"frames": [{"frame_idx": 89, "latency_ms": 32792, "description": "### Frame Analysis:\\n\\n#### Frame 1:\\n- **Scene**: Two workers are working at a quality control station.\\n- **Workers**: Both workers are wearing gloves, masks, and caps.\\n- **Tools**: Workers are using a machine to inspect can lids.\\n- **Environment**: The workspace is clean with clear labels for \\"GOOD\\" and \\"NG\\" trays.\\n- **Procedure**:\\n  - **Step 1**: Workers are preparing the work area by ensuring the conveyor, NG tray, and GOOD tray are in place.\\n  - **Step 2**: Worker 1 picks up cans and inspects them visually.\\n  - **Step 3**: Worker 1 places good cans on the conveyor.\\n  - **Step 4**: The conveyor scans the cans through an AI camera.\\n  - **Step 5**: Worker 2 picks up cans from the conveyor.\\n  - **Step 6**: Worker 2 cleans the cans thoroughly.\\n  - **Step 7**: Worker 2 packs the cleaned cans into the GOOD tray.\\n\\n#### Frame 2:\\n- **Scene**: Similar setup as Frame 1.\\n- **Workers**: Workers are still wearing gloves, masks, and caps.\\n- **Tools**: Workers are using a machine to inspect can lids.\\n- **Environment**: The workspace is clean with clear labels for \\"GOOD\\" and \\"NG\\" trays.\\n- **Procedure**:\\n  - **Step 1**: Workers are preparing the work area by ensuring the conveyor, NG", "timestamp_sec": 2.97, "timestamp_str": "0:00:00 – 0:00:05", "frames_in_batch": 3}, {"frame_idx": 356, "latency_ms": 32140, "description": "### Frame Analysis:\\n\\n#### Frame 1:\\n- **Scene**: Workers are inspecting cans on a conveyor.\\n- **Workers**: Two workers wearing gloves, masks, and caps.\\n- **Tools**: Conveyor system with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor belt with a conveyor belt, conveyor", "timestamp_sec": 11.87, "timestamp_str": "0:00:08 – 0:00:14", "frames_in_batch": 3}, {"frame_idx": 623, "latency_ms": 32870, "description": "### Frame Analysis:\\n\\n#### Frame 1:\\n- **Scene**: Workers are inspecting cans on a conveyor.\\n- **Workers**: Two workers wearing gloves, masks, and caps.\\n- **Tools**: Conveyor, conveyor belt, conveyor belt with a conveyor belt system.\\n- **Environment**: Clean workspace with clear instructions and materials.\\n\\n#### Frame 2:\\n- **Scene**: Workers are handling cans on a conveyor.\\n- **Workers**: Two workers wearing gloves, masks, and caps.\\n- **Tools**: Conveyor, conveyor belt, conveyor belt with a conveyor belt system.\\n- **Environment**: Clean workspace with clear instructions and materials.\\n\\n### Comparison with SOP:\\n\\n#### Compliance with SOP:\\n- **Step 1**: Workers are preparing the work area, which is consistent with the SOP.\\n- **Step 2**: Workers are picking cans from the raw material box, which is consistent with the SOP.\\n- **Step 3**: Workers are inspecting cans by eye, which is consistent with the SOP.\\n- **Step 4**: Workers are placing good cans on the conveyor, which is consistent with the SOP.\\n- **Step 5**: Workers are scanning cans through an AI camera, which is consistent with the SOP.\\n- **Step 6**: Workers are picking cans from the conveyor, which is consistent with the SOP.\\n- **Step 7**: Workers are cleaning cans, which is consistent with the SOP.\\n- **Step 8**: Workers are packing good cans into boxes, which is consistent with", "timestamp_sec": 20.78, "timestamp_str": "0:00:17 – 0:00:23", "frames_in_batch": 3}, {"frame_idx": 890, "latency_ms": 32383, "description": "### Frame Analysis:\\n\\n#### Frame 1:\\n- **Scene**: Workers are inspecting cans on a production line.\\n- **Workers**: Two workers wearing gloves, masks, and caps.\\n- **Tools**: Conveyor belt, conveyor belt control panel, NG tray, Good tray, and a scale.\\n- **Environment**: Clean and organized workspace with clear signage indicating 'GOOD' and 'NG'.\\n\\n#### Frame 2:\\n- **Scene**: Workers continue the inspection process.\\n- **Workers**: Workers are handling cans, checking them visually, and placing good cans on the conveyor while rejecting bad ones into the NG tray.\\n- **Tools**: Same as Frame 1.\\n- **Environment**: Similar clean and organized workspace.\\n\\n### Comparison with SOP:\\n\\n#### Compliance with SOP:\\n- **Step 1**: Workers are preparing the work area, which is consistent with the SOP.\\n- **Step 2**: Workers are picking cans one by one, which aligns with the SOP.\\n- **Step 3**: Workers are visually inspecting the cans, which matches the SOP.\\n- **Step 4**: Workers are placing good cans on the conveyor, which is consistent with the SOP.\\n- **Step 5**: Workers are scanning the cans through an AI camera, which is also aligned with the SOP.\\n- **Step 6**: Workers are removing cans from the conveyor, which is consistent with the SOP.\\n- **Step 7**: Workers are cleaning the cans, which is consistent with the SOP.\\n- **", "timestamp_sec": 29.69, "timestamp_str": "0:00:26 – 0:00:32", "frames_in_batch": 3}, {"frame_idx": 1157, "latency_ms": 30675, "description": "### Frame Analysis:\\n\\n#### Frame 1:\\n- **Worker 1** is holding a can and inspecting it with his eyes.\\n- **Worker 2** is holding another can and appears to be preparing to inspect it.\\n- **Conveyor belt** is visible with some cans on it.\\n- **NG tray** and **Good tray** boxes are present on the table.\\n- **Safety glasses** are visible on the table, but **Worker 1** is not wearing them.\\n- **Safety shoes** are visible, but **Worker 2** is not wearing them.\\n- **Gloves** are visible, but **Worker 1** is not wearing them.\\n- **Mask** is visible, but **Worker 1** is not wearing it.\\n- **Cap** is visible, but **Worker 1** is not wearing it.\\n\\n#### Frame 2:\\n- **Worker 1** is placing a can on the conveyor belt.\\n- **Worker 2** is picking up a can from the conveyor belt.\\n- **Conveyor belt** is moving, and **Worker 2** is handling the can carefully.\\n- **Safety glasses** are visible on the table, but **Worker 2** is not wearing them.\\n- **Safety shoes** are visible, but **Worker 2** is not wearing them.\\n- **Gloves** are visible, but **Worker 2** is not wearing them.\\n- **Mask** is visible, but", "timestamp_sec": 38.59, "timestamp_str": "0:00:35 – 0:00:41", "frames_in_batch": 3}, {"frame_idx": 1424, "latency_ms": 32930, "description": "### Frame Analysis:\\n\\n#### Frame 1:\\n- **Scene**: Workers are inspecting cans on a conveyor.\\n- **Workers**: Two workers wearing gloves, masks, and caps.\\n- **Equipment**: A conveyor system with a quality control station.\\n- **Objects**: Cans on conveyor, NG tray, Good tray, and a machine for quality inspection.\\n\\n#### Frame 2:\\n- **Scene**: Workers continue inspecting cans.\\n- **Workers**: Workers are handling cans and placing them on the conveyor.\\n- **Equipment**: Same conveyor system with a quality control station.\\n- **Objects**: Cans on conveyor, NG tray, Good tray, and a machine for quality inspection.\\n\\n### Comparison with SOP:\\n\\n#### Compliance with SOP:\\n- **Step 1**: Workers are preparing the work area by ensuring the NG tray, Good tray, and conveyor are in place.\\n- **Step 2**: Workers are picking cans one by one from the raw material box and holding them gently without damaging them.\\n- **Step 3**: Workers are checking the cans under the light to ensure there are no defects. This step is critical and requires careful inspection.\\n- **Step 4**: Workers are placing good cans on the conveyor in the designated position. This step involves handling the conveyor carefully to avoid injuries.\\n- **Step 5**: The conveyor scans the cans using an AI camera to check them automatically. This step is crucial for quality assurance.\\n- **Step 6**: Workers are picking cans from the conveyor", "timestamp_sec": 47.5, "timestamp_str": "0:00:44 – 0:00:50", "frames_in_batch": 3}, {"frame_idx": 1602, "latency_ms": 33694, "description": "### Frame Analysis:\\n\\n#### Frame 1:\\n- **Scene**: Workers are inspecting cans on a conveyor.\\n- **Workers**: Two workers wearing gloves, masks, and caps.\\n- **Tools**: Conveyor system with a conveyor belt.\\n- **Environment**: Clean workspace with clear signage indicating 'GOOD' and 'NG' trays.\\n\\n#### Frame 2:\\n- **Scene**: Workers continue the inspection process.\\n- **Workers**: Workers are handling cans and placing them on the conveyor.\\n- **Tools**: Conveyor system with a conveyor belt.\\n- **Environment**: Clean workspace with clear signage indicating 'GOOD' and 'NG' trays.\\n\\n### Comparison with SOP:\\n\\n#### Compliance with SOP:\\n- **Step 1**: Workers are preparing the work area, which is consistent with the SOP.\\n- **Step 2**: Workers are picking cans from the raw material box, which aligns with the SOP.\\n- **Step 3**: Workers are checking the cans visually, which matches the SOP requirement of using the eye for inspection.\\n- **Step 4**: The conveyor system is used to move the cans, which is consistent with the SOP.\\n- **Step 5**: The conveyor system scans the cans through an AI camera, which aligns with the SOP.\\n- **Step 6**: Workers are removing cans from the conveyor, which is consistent with the SOP.\\n- **Step 7**: Workers are cleaning the cans, which is consistent with the SOP.\\n- **Step 8**: Workers are packing", "timestamp_sec": 53.43, "timestamp_str": "0:00:53 – 0:00:53", "frames_in_batch": 1}], "status": "ok", "vlm_input": {"settings": {"file": "Mock Station1_60pct.mp4", "max_frames": 19, "resolution": 480, "multi_frame": 3, "interval_sec": 3, "max_new_tokens": 300}, "prompt_base": "{\\n  \\"operation\\": {\\n    \\"name\\": \\"Quality Control Station – Can Inspection\\",\\n    \\"description\\": \\"การตรวจสอบคุณภาพกระป๋องด้วยสายตาก่อนส่งต่อกระบวนการถัดไปผ่านสายพานลำเลียง\\",\\n    \\"roles\\": {\\n      \\"Worker1\\": \\"หยิบกระป๋อง ตรวจสอบด้วยสายตา วางกระป๋องดีลงบน conveyor วางกระป๋องเสียลง NG tray\\",\\n      \\"Worker2\\": \\"หยิบกระป๋องออกจาก conveyor เช็ดทุกด้าน แพ็คใส่กล่อง Good\\"\\n    },\\n    \\"ppe_specifications\\": {\\n      \\"helmet\\": {\\n        \\"required\\": true,\\n        \\"acceptable_types\\": [\\n          \\"หมวก safety helmet มาตรฐาน\\",\\n          \\"หมวก cap / แก๊ป\\"\\n        ],\\n        \\"not_acceptable\\": [\\n          \\"ไม่สวมหมวกเลย\\"\\n        ],\\n        \\"how_to_identify\\": \\"สวมอยู่บนศีรษะ ไม่ว่าจะเป็นแบบใดก็ถือว่าผ่าน — ผิดเฉพาะกรณีไม่สวม\\"\\n      },\\n      \\"safety_shoes\\": {\\n        \\"required\\": true,\\n        \\"acceptable_types\\": [\\n          \\"รองเท้านิรภัยหัวเหล็ก EN ISO 20345\\",\\n          \\"รองเท้าหัวเหล็กทั่วไป\\"\\n        ],\\n        \\"not_acceptable\\": [\\n          \\"รองเท้าแตะ\\",\\n          \\"รองเท้าผ้าใบธรรมดา\\",\\n          \\"รองเท้าหนังไม่มีหัวเหล็ก\\",\\n          \\"เท้าเปล่า\\"\\n        ],\\n        \\"how_to_identify\\": \\"รองเท้าหุ้มส้น มีหัวแข็ง ดูหนาและแข็งแรง\\"\\n      },\\n      \\"gloves\\": {\\n        \\"required\\": true,\\n        \\"acceptable_types\\": [\\n          \\"ถุงมือยาง / latex\\",\\n          \\"ถุงมือผ้า\\",\\n          \\"ถุงมือ nitrile\\",\\n          \\"ถุงมือหนัง\\"\\n        ],\\n        \\"not_acceptable\\": [\\n          \\"ไม่สวมถุงมือเลย\\"\\n        ],\\n        \\"how_to_identify\\": \\"มีวัสดุหุ้มมือ ไม่ว่าชนิดใด — ผิดเฉพาะกรณีไม่สวม\\"\\n      },\\n      \\"mask\\": {\\n        \\"required\\": true,\\n        \\"acceptable_types\\": [\\n          \\"หน้ากากอนามัย\\",\\n          \\"N95\\",\\n          \\"หน้ากากผ้า\\"\\n        ],\\n        \\"not_acceptable\\": [\\n          \\"ดึงหน้ากากลงคาง\\",\\n          \\"แขวนหน้ากากที่หู\\",\\n          \\"ไม่สวมเลย\\"\\n        ],\\n        \\"how_to_identify\\": \\"หน้ากากต้องปิดจมูกและปากพร้อมกัน\\"\\n      },\\n      \\"safety_glasses\\": {\\n        \\"required\\": false,\\n        \\"note\\": \\"ต้องการเฉพาะเมื่อใช้สารเคมีทำความสะอาด\\"\\n      },\\n      \\"safety_vest\\": {\\n        \\"required\\": false,\\n        \\"note\\": \\"ไม่จำเป็นในสถานีนี้\\"\\n      }\\n    },\\n    \\"sop_steps\\": [\\n      {\\n        \\"step\\": 1,\\n        \\"title\\": \\"เตรียมพื้นที่ทำงาน\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"ตรวจสอบ NG tray กล่อง Good และ conveyor ให้อยู่ในตำแหน่ง ตรวจสอบว่า conveyor ทำงานได้\\"\\n      },\\n      {\\n        \\"step\\": 2,\\n        \\"title\\": \\"หยิบกระป๋อง\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"Worker1 หยิบกระป๋องทีละใบจากกล่องวัตถุดิบ จับเบาๆ เพื่อไม่ให้บุบ\\"\\n      },\\n      {\\n        \\"step\\": 3,\\n        \\"title\\": \\"ตรวจสอบด้วยสายตา\\",\\n        \\"skippable\\": false,\\n        \\"critical\\": true,\\n        \\"detail\\": \\"ตรวจสอบทุกด้านของกระป๋องภายใต้แสงที่เพียงพอ ตรวจหารอยบุบ สนิม การเสียรูป การปนเปื้อน\\"\\n      },\\n      {\\n        \\"step\\": 4,\\n        \\"title\\": \\"คัดแยกกระป๋อง\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"กระป๋องเสีย → NG tray เท่านั้น กระป๋องดี → วางราบบน conveyor ในตำแหน่งที่กำหนด\\",\\n        \\"hazard\\": \\"Conveyor หนีบมือ\\",\\n        \\"hazard_severity\\": \\"HIGH\\"\\n      },\\n      {\\n        \\"step\\": 5,\\n        \\"title\\": \\"สแกนด้วย AI camera\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"conveyor เลื่อนกระป๋องผ่านกล้อง AI เพื่อตรวจสอบอัตโนมัติ\\"\\n      },\\n      {\\n        \\"step\\": 6,\\n        \\"title\\": \\"หยิบกระป๋องออกจาก conveyor\\",\\n        \\"skippable\\": false,\\n        \\"critical\\": true,\\n        \\"detail\\": \\"Worker2 หยิบกระป๋องที่ออกมาพ้นสายพานแล้ว หรือรอให้ conveyor หยุดก่อน — การหยิบกระป๋องที่ปลาย conveyor ในตำแหน่งรับของที่กำหนดถือเป็นการทำงานปกติ ผิดเฉพาะกรณีที่มือเข้าไปใน belt area ที่กำลังเคลื่อนที่\\",\\n        \\"hazard\\": \\"Conveyor หนีบมือ\\",\\n        \\"hazard_severity\\": \\"HIGH\\"\\n      },\\n      {\\n        \\"step\\": 7,\\n        \\"title\\": \\"เช็ดกระป๋อง\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"เช็ดทุกด้าน (บน ข้าง ล่าง) ด้วยผ้าสะอาดก่อนแพ็ค\\",\\n        \\"hazard\\": \\"กระป๋องหล่น\\",\\n        \\"hazard_severity\\": \\"MEDIUM\\"\\n      },\\n      {\\n        \\"step\\": 8,\\n        \\"title\\": \\"แพ็คใส่กล่อง Good\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"วางกระป๋องเรียบร้อยในกล่อง Good ห้ามวางเกินความสูงที่กำหนด\\"\\n      }\\n    ],\\n    \\"inspection_criteria\\": {\\n      \\"purpose\\": \\"เกณฑ์ตัดสินมาตรฐานสำหรับ Worker1 ในการคัดแยกกระป๋อง Good vs NG\\",\\n      \\"defect_types\\": {\\n        \\"dent\\": {\\n          \\"name\\": \\"รอยบุบ\\",\\n          \\"pass\\": \\"รอยบุบเล็กน้อยที่ไม่กระทบรูปทรงโดยรวม ขนาด < 3 mm และไม่อยู่บริเวณขอบหรือฝากระป๋อง\\",\\n          \\"ng\\": \\"รอยบุบลึกหรือกว้าง >= 3 mm, รอยบุบบริเวณขอบหรือฝา, รอยบุบที่ทำให้กระป๋องเสียรูปทรง\\",\\n          \\"severity\\": \\"HIGH\\"\\n        },\\n        \\"rust\\": {\\n          \\"name\\": \\"สนิม\\",\\n          \\"pass\\": \\"ไม่มีสนิมใดๆ\\",\\n          \\"ng\\": \\"พบจุดสนิมหรือคราบสีน้ำตาล/แดงใดๆ บนผิวกระป๋อง ไม่ว่าขนาดเล็กเพียงใด\\",\\n          \\"severity\\": \\"HIGH\\"\\n        },\\n        \\"deformation\\": {\\n          \\"name\\": \\"การเสียรูป\\",\\n          \\"pass\\": \\"กระป๋องทรงกระบอกตรง ปิดฝาได้สนิท\\",\\n          \\"ng\\": \\"กระป๋องบิดเบี้ยว บวม โป่ง หรือฝาปิดไม่สนิท\\",\\n          \\"severity\\": \\"CRITICAL\\"\\n        },\\n        \\"contamination\\": {\\n          \\"name\\": \\"การปนเปื้อน\\",\\n          \\"pass\\": \\"ผิวกระป๋องสะอาด ไม่มีสิ่งแปลกปลอม\\",\\n          \\"ng\\": \\"พบคราบน้ำมัน สารเคมี สิ่งสกปรก หรือวัตถุแปลกปลอมติดผิวกระป๋อง\\",\\n          \\"severity\\": \\"HIGH\\"\\n        },\\n        \\"scratch\\": {\\n          \\"name\\": \\"รอยขีดข่วน\\",\\n          \\"pass\\": \\"รอยขีดตื้นที่ไม่ทะลุผิวเคลือบ\\",\\n          \\"ng\\": \\"รอยขีดที่ทะลุผิวเคลือบจนเห็นเนื้อโลหะ หรือรอยยาวต่อเนื่อง > 10 mm\\",\\n          \\"severity\\": \\"MEDIUM\\"\\n        },\\n        \\"label_defect\\": {\\n          \\"name\\": \\"ฉลาก/พิมพ์ผิดปกติ\\",\\n          \\"pass\\": \\"ตัวอักษรและโลโก้ชัดเจน ไม่เบี้ยว\\",\\n          \\"ng\\": \\"ฉลากเบี้ยว ลอก หรือตัวอักษรไม่ชัดเจน\\",\\n          \\"severity\\": \\"MEDIUM\\"\\n        },\\n        \\"opening\\": {\\n          \\"name\\": \\"ฝา/ช่องเปิด\\",\\n          \\"pass\\": \\"ฝาอยู่ในตำแหน่งปกติ ไม่มีการเปิดบางส่วน\\",\\n          \\"ng\\": \\"ฝาเปิดอยู่บางส่วน ฝาหลุด หรือซีลขาด\\",\\n          \\"severity\\": \\"CRITICAL\\"\\n        }\\n      },\\n      \\"inspection_method\\": [\\n        \\"หมุนกระป๋อง 360° เพื่อตรวจทุกด้าน\\",\\n        \\"ตรวจด้านบน (ฝา) และด้านล่าง (ก้น) ด้วย\\",\\n        \\"ตรวจภายใต้แสงสว่างที่เพียงพอเสมอ\\",\\n        \\"หากสงสัยให้จัดเป็น NG ก่อน แจ้ง Supervisor ตรวจซ้ำ\\"\\n      ],\\n      \\"ng_rate_threshold\\": {\\n        \\"warning\\": \\"NG > 10% ใน 1 ชั่วโมง → แจ้ง Supervisor ทันที\\",\\n        \\"stop_line\\": \\"NG > 20% ใน 1 ชั่วโมง → หยุดสายการผลิต รอการตรวจสอบจาก Supervisor\\",\\n        \\"warning_severity\\": \\"MEDIUM\\",\\n        \\"stop_line_severity\\": \\"HIGH\\"\\n      }\\n    },\\n    \\"step_sequence_rules\\": {\\n      \\"must_follow_order\\": true,\\n      \\"critical_steps\\": [\\n        3,\\n        6\\n      ],\\n      \\"skip_severity\\": {\\n        \\"step_3\\": \\"MEDIUM — ข้ามการตรวจสอบด้วยสายตา กระป๋องเสียอาจผ่านไปสายพาน\\",\\n        \\"step_6\\": \\"CRITICAL — หยิบกระป๋องขณะสายพานยังวิ่ง เสี่ยงมือติดสายพาน\\",\\n        \\"step_7\\": \\"MEDIUM — ไม่เช็ดกระป๋อง คุณภาพสินค้าต่ำลง\\",\\n        \\"other_steps\\": \\"LOW — เบี่ยงเบนจาก SOP เล็กน้อย\\"\\n      },\\n      \\"out_of_order_severity\\": \\"MEDIUM\\",\\n      \\"rushing_signs\\": [\\n        \\"Worker1 วางกระป๋องลง conveyor โดยไม่หยุดตรวจสอบ\\",\\n        \\"Worker2 หยิบกระป๋องออกก่อนที่จะออกจากสายพาน\\",\\n        \\"ข้ามขั้นตอนเช็ดกระป๋องเพื่อเร่งความเร็ว\\"\\n      ]\\n    },\\n    \\"personnel_management\\": {\\n      \\"authorized_roles\\": {\\n        \\"Worker1\\": {\\n          \\"zone_access\\": \\"เต็มพื้นที่\\",\\n          \\"ppe_required\\": \\"ครบทุกชิ้น\\"\\n        },\\n        \\"Worker2\\": {\\n          \\"zone_access\\": \\"เต็มพื้นที่\\",\\n          \\"ppe_required\\": \\"ครบทุกชิ้น\\"\\n        },\\n        \\"Supervisor\\": {\\n          \\"zone_access\\": \\"เข้าได้ตรวจสอบ ห้ามแทรกแซงการทำงาน\\",\\n          \\"ppe_required\\": \\"รองเท้านิรภัยและหมวกอย่างน้อย\\",\\n          \\"max_duration\\": \\"ไม่จำกัด\\",\\n          \\"severity_if_no_ppe\\": \\"MEDIUM\\"\\n        },\\n        \\"Maintenance\\": {\\n          \\"zone_access\\": \\"เข้าได้เฉพาะเมื่อ conveyor หยุดและมี Work Permit\\",\\n          \\"ppe_required\\": \\"ครบทุกชิ้นตามงาน\\",\\n          \\"severity_if_enter_during_operation\\": \\"HIGH\\"\\n        }\\n      },\\n      \\"cross_zone_worker\\": {\\n        \\"definition\\": \\"พนักงานจาก zone อื่นเข้ามาแจ้งงานหรือส่งของ\\",\\n        \\"allowed\\": true,\\n        \\"conditions\\": [\\n          \\"ต้องอยู่นอก boundary line ของสถานีทำงาน\\",\\n          \\"ต้องสวมรองเท้านิรภัยอย่างน้อย\\",\\n          \\"ห้ามสัมผัสกระป๋องหรืออุปกรณ์\\",\\n          \\"ระยะเวลาไม่เกิน 2 นาที\\",\\n          \\"ห้ามส่งอาหาร เครื่องดื่ม หรือสิ่งของส่วนตัวเข้ามาในพื้นที่ปฏิบัติงาน\\"\\n        ],\\n        \\"severity_if_violate\\": \\"MEDIUM\\"\\n      },\\n      \\"unauthorized_person\\": {\\n        \\"definition\\": \\"บุคคลที่ไม่มีธุระในพื้นที่ เช่น บุคคลภายนอก ผู้เยี่ยมชมที่ไม่มี escort\\",\\n        \\"allowed\\": false,\\n        \\"immediate_response\\": [\\n          \\"Worker หยุดงานทันที\\",\\n          \\"แจ้งให้บุคคลออกจากพื้นที่\\",\\n          \\"แจ้ง Supervisor ทันที\\",\\n          \\"กลับทำงานเมื่อพื้นที่ปลอดภัยแล้วเท่านั้น\\"\\n        ],\\n        \\"severity\\": \\"LOW\\"\\n      },\\n      \\"person_count_alert\\": {\\n        \\"normal\\": 2,\\n        \\"alert_if_more_than\\": 3,\\n        \\"alert_severity\\": \\"MEDIUM\\"\\n      }\\n    },\\n    \\"incident_types\\": {\\n      \\"near_miss\\": {\\n        \\"definition\\": \\"เหตุการณ์ที่เกือบเกิดอุบัติเหตุแต่ไม่มีการบาดเจ็บ\\",\\n        \\"examples\\": [\\n          \\"มือเกือบโดน conveyor แต่ดึงออกทัน\\",\\n          \\"กระป๋องเกือบตกแต่รับทัน\\",\\n          \\"สะดุดแต่ไม่ล้ม\\",\\n          \\"กระป๋องเกือบหล่นใส่เท้า\\"\\n        ],\\n        \\"severity\\": \\"HIGH\\",\\n        \\"required_action\\": \\"หยุดงาน รายงาน Supervisor ทันที บันทึก Near-Miss Report\\"\\n      },\\n      \\"property_damage\\": {\\n        \\"definition\\": \\"อุปกรณ์หรือสินค้าเสียหาย\\",\\n        \\"examples\\": [\\n          \\"กระป๋องตกพื้น\\",\\n          \\"กล่อง Good ล้ม\\",\\n          \\"NG tray ล้น\\"\\n        ],\\n        \\"severity\\": \\"CRITICAL\\",\\n        \\"required_action\\": \\"หยุดงาน เก็บของที่ตก แจ้ง Supervisor\\"\\n      },\\n      \\"minor_injury\\": {\\n        \\"definition\\": \\"บาดเจ็บเล็กน้อย\\",\\n        \\"examples\\": [\\n          \\"บาดมือจากขอบกระป๋อง\\",\\n          \\"ของตกใส่เท้า\\",\\n          \\"ลื่นล้มเล็กน้อย\\"\\n        ],\\n        \\"severity\\": \\"HIGH\\",\\n        \\"required_action\\": \\"หยุดงานทันที ปฐมพยาบาล แจ้ง Supervisor บันทึก Incident Report\\"\\n      },\\n      \\"major_injury\\": {\\n        \\"definition\\": \\"บาดเจ็บสาหัส\\",\\n        \\"examples\\": [\\n          \\"มือติด conveyor\\",\\n          \\"ล้มศีรษะกระแทก\\",\\n          \\"หมดสติ\\"\\n        ],\\n        \\"severity\\": \\"CRITICAL\\",\\n        \\"required_action\\": [\\n          \\"กดปุ่ม Emergency Stop ทันที\\",\\n          \\"โทร 1669 หรือหน่วยฉุกเฉินโรงงาน\\",\\n          \\"ห้ามเคลื่อนย้ายผู้บาดเจ็บจนกว่าทีมแพทย์จะมาถึง\\",\\n          \\"แจ้ง Supervisor และ Safety Officer ทันที\\",\\n          \\"ห้ามเดินเครื่องจนกว่าจะได้รับอนุญาต\\"\\n        ]\\n      }\\n    },\\n    \\"hygiene_rules\\": {\\n      \\"purpose\\": \\"ป้องกันการปนเปื้อนในผลิตภัณฑ์\\",\\n      \\"rules\\": [\\n        \\"ห้ามสัมผัสหน้า ผม หู จมูก ปาก ขณะสวมถุงมือที่ใช้จับกระป๋อง\\",\\n        \\"หากสัมผัสหน้า ต้องเปลี่ยนถุงมือใหม่ก่อนหยิบกระป๋องต่อ\\",\\n        \\"กระป๋องที่ตกพื้นถือว่าเป็น NG ต้องใส่ NG tray เสมอ ห้ามหยิบขึ้นมาใช้\\",\\n        \\"ถุงมือขาดหรือสกปรกต้องเปลี่ยนทันที\\",\\n        \\"ห้ามรับประทานอาหารหรือดื่มน้ำในพื้นที่ทำงาน\\",\\n        \\"Worker2 ต้องเช็ดกระป๋องครบทุกด้าน (บน ข้าง ล่าง) ห้ามข้ามด้านใดด้านหนึ่ง\\",\\n        \\"ห้ามรับอาหาร เครื่องดื่ม หรือสิ่งของส่วนตัวจากบุคคลภายนอกขณะปฏิบัติงานในพื้นที่\\"\\n      ],\\n      \\"violation_severity\\": \\"MEDIUM\\"\\n    },\\n    \\"ergonomics_rules\\": {\\n      \\"purpose\\": \\"ป้องกันการบาดเจ็บจากการทำงานซ้ำๆ และท่าทางที่ไม่ถูกต้อง\\",\\n      \\"normal_posture_note\\": \\"การก้มตัวเล็กน้อยเพื่อหยิบกระป๋องเป็นเรื่องปกติของงานนี้ ไม่ต้อง flag\\",\\n      \\"flag_only_when\\": [\\n        \\"ก้มหลังอย่างรุนแรง (หลังขนานพื้น) ซ้ำๆ ติดต่อกันหลายครั้ง\\",\\n        \\"บิดเอวขณะถือกระป๋อง\\",\\n        \\"แสดงอาการเจ็บปวดชัดเจน เช่น จับหลัง หยุดพักบ่อยผิดปกติ\\",\\n        \\"ท่าทางแย่ลงเรื่อยๆ เห็นได้ชัดตลอดวิดีโอ\\"\\n      ],\\n      \\"do_not_flag\\": [\\n        \\"การก้มเล็กน้อยเพื่อหยิบกระป๋อง 1-2 ครั้ง\\",\\n        \\"ท่าทางปกติของงาน QC\\",\\n        \\"การเอื้อมมือไปข้างหน้าในระยะสั้น\\"\\n      ],\\n      \\"severity_guide\\": {\\n        \\"severe_repeated_bending\\": \\"LOW\\",\\n        \\"twisting_with_load\\": \\"MEDIUM\\",\\n        \\"visible_pain_signs\\": \\"MEDIUM\\"\\n      }\\n    },\\n    \\"behavior_rules\\": {\\n      \\"focus_requirements\\": [\\n        \\"ห้ามใช้โทรศัพท์มือถือขณะปฏิบัติงาน\\",\\n        \\"ห้ามคุยกันในลักษณะที่เสียสมาธิจากการตรวจสอบ\\",\\n        \\"ห้ามฟังเพลงหรือสวมหูฟังขณะทำงาน\\"\\n      ],\\n      \\"behavior_violations\\": {\\n        \\"phone_use\\": {\\n          \\"severity\\": \\"MEDIUM\\",\\n          \\"description\\": \\"ใช้โทรศัพท์ขณะทำงาน\\"\\n        },\\n        \\"distracted_talk\\": {\\n          \\"severity\\": \\"LOW\\",\\n          \\"description\\": \\"คุยกันเกินความจำเป็น\\"\\n        },\\n        \\"rushing\\": {\\n          \\"severity\\": \\"HIGH\\",\\n          \\"description\\": \\"ทำงานเร็วเกินจนข้ามขั้นตอนตรวจ\\"\\n        },\\n        \\"fatigue_visible\\": {\\n          \\"severity\\": \\"LOW\\",\\n          \\"description\\": \\"แสดงอาการเมื่อยล้าชัดเจน\\"\\n        }\\n      }\\n    },\\n    \\"conveyor_rules\\": [\\n      \\"ห้ามเอื้อมมือเข้าไปใน conveyor ที่กำลังวิ่ง\\",\\n      \\"วางกระป๋องในตำแหน่งและทิศทางที่กำหนดบน conveyor เท่านั้น\\",\\n      \\"หาก conveyor ติดขัด ให้หยุดเครื่องก่อนแก้ไขเสมอ\\",\\n      \\"กระป๋องที่สะสมบน conveyor มากเกินไปต้องรายงาน Supervisor\\",\\n      \\"ห้ามวางสิ่งของอื่นบน conveyor นอกจากกระป๋องที่ผ่านการตรวจแล้ว\\",\\n      \\"ห้าม Worker1/Worker2 ปรับ ซ่อม หรือถอดชิ้นส่วนสายพานเอง — ให้หยุดเครื่อง รายงาน Supervisor และรอ Maintenance ดำเนินการ\\"\\n    ],\\n    \\"prohibited_actions\\": [\\n      \\"เอื้อมมือเข้า conveyor ที่กำลังวิ่ง (CRITICAL)\\",\\n      \\"หยิบกระป๋องขณะ conveyor ยังทำงาน (CRITICAL)\\",\\n      \\"ใส่กระป๋อง NG ลงกล่อง Good (HIGH)\\",\\n      \\"ข้ามขั้นตอนการตรวจสอบด้วยสายตา (HIGH)\\",\\n      \\"วางกระป๋องที่ตกพื้นกลับเข้า Good (MEDIUM)\\",\\n      \\"ใช้โทรศัพท์ขณะปฏิบัติงาน (MEDIUM)\\",\\n      \\"บุคคลที่ไม่เกี่ยวข้องเข้าพื้นที่โดยไม่มี escort (LOW)\\",\\n      \\"ทำงานโดยไม่สวม PPE ครบ (MEDIUM)\\",\\n      \\"วางของที่ไม่เกี่ยวข้องกับงานไว้ในพื้นที่ทำงาน (MEDIUM)\\",\\n      \\"รับอาหารหรือเครื่องดื่มจากบุคคลภายนอกในพื้นที่ทำงาน (MEDIUM)\\",\\n      \\"Worker ปรับหรือซ่อมสายพานด้วยตนเองโดยไม่มี Maintenance (HIGH)\\"\\n    ],\\n    \\"unsafe_conditions\\": [\\n      \\"พื้นเปียกหรือลื่น\\",\\n      \\"กระป๋องกระจายบนพื้น (เสี่ยงสะดุด/ลื่น)\\",\\n      \\"แสงสว่างไม่เพียงพอสำหรับการตรวจสอบด้วยสายตา\\",\\n      \\"conveyor ขัดข้อง ติดขัด หรือวิ่งเร็วผิดปกติ\\",\\n      \\"NG tray เต็มเกินไป (เสี่ยงล้น)\\",\\n      \\"พื้นที่รก ไม่เป็นระเบียบ (5S ไม่ผ่าน)\\",\\n      \\"มีสิ่งของที่ไม่เกี่ยวข้องกับงาน (เช่น อาหาร เครื่องดื่ม ของส่วนตัว) วางในพื้นที่ทำงาน\\"\\n    ],\\n    \\"safe_practices\\": [\\n      \\"รักษาพื้นที่ทำงานให้สะอาดและเป็นระเบียบ (5S)\\",\\n      \\"รายงานความผิดปกติของ conveyor ต่อ Supervisor ทันที\\",\\n      \\"ไม่เร่งรีบตรวจสอบ — คุณภาพสำคัญกว่าความเร็ว\\",\\n      \\"เปลี่ยนถุงมือเมื่อขาดหรือสกปรก\\",\\n      \\"บันทึก Near-Miss ทุกครั้งแม้ไม่มีการบาดเจ็บ\\"\\n    ]\\n  }\\n}", "sop_context": "=== SOP Context: Production Line (SOP-002) ===\\r\\nProcess: Inspection and Clean the Can.\\r\\nPPE Required: ถุงมือผ้า, หน้ากากอนามัย, หมวกcap, รองเท้า Safety\\r\\nWork Steps:\\r\\n  1. กระป๋องรอเข้ากระกวนการตรวจสอบคุณภาพถูกวางอยู่ในลัง [Risk: Low]\\r\\n  2. worker1  หยิบกระป๋องเเละตรวจสอบด้วยสายตา หากพบกระป๋องผิดปกติให้หยิบออกใส่ถาด NG [Risk: Low]\\r\\n  3. worker1  วางกระป๋องที่สภาพดีลงบน conveyer  — ระวัง Conveyor หนีบมือ [Risk: High]\\r\\n  4. Conveyour เลื่อนกระป๋องผ่านกล้องเพื่อถ่ายรูปกระป๋องและตรวจสอบด้วย AI  [Risk: Low]\\r\\n  5. worker2  หยิบกระป๋องออกจาก conveyor — ระวัง Conveyor หนีบมือ [Risk: High]\\r\\n  6. worker2  เช็ดกระป๋องให้ครบทุกด้าน — ระวังกระป๋องหล่น [Risk: Medium]\\r\\n  7. worker2  เก็บใส่ลัง Good เพื่อส่งกระบวนการถัดไป [Risk: Low]\\r\\nSafety Rules:\\r\\n  - [Critical] กระป๋องหล่น\\r\\n  - [Medium] ไม่ใส่อุปกรณ์ PPE\\r\\n  - [Critical] สายพานหนีบมือ\\r\\n  - [Low] บุคคลอื่นเข้าพื้นที่ทำงาน\\r\\n  - [Medium] วางของที่ไม่เกี่ยวข้องกับงานไว้ในพื้นที่ทำงาน\\r\\n  - [Medium] ทำงานข้ามขั้นตอน ไม่เช็ดกระป๋อง\\r\\n  - [Medium] ทำงานข้ามขั้นตอน ไม่ตรวจสอบด้วยสายตาก่อนนำขึ้นสายพาน", "full_prompt_sent": "=== REFERENCE SOP (USE AS GROUND TRUTH) ===\\n=== SOP Context: Production Line (SOP-002) ===\\r\\nProcess: Inspection and Clean the Can.\\r\\nPPE Required: ถุงมือผ้า, หน้ากากอนามัย, หมวกcap, รองเท้า Safety\\r\\nWork Steps:\\r\\n  1. กระป๋องรอเข้ากระกวนการตรวจสอบคุณภาพถูกวางอยู่ในลัง [Risk: Low]\\r\\n  2. worker1  หยิบกระป๋องเเละตรวจสอบด้วยสายตา หากพบกระป๋องผิดปกติให้หยิบออกใส่ถาด NG [Risk: Low]\\r\\n  3. worker1  วางกระป๋องที่สภาพดีลงบน conveyer  — ระวัง Conveyor หนีบมือ [Risk: High]\\r\\n  4. Conveyour เลื่อนกระป๋องผ่านกล้องเพื่อถ่ายรูปกระป๋องและตรวจสอบด้วย AI  [Risk: Low]\\r\\n  5. worker2  หยิบกระป๋องออกจาก conveyor — ระวัง Conveyor หนีบมือ [Risk: High]\\r\\n  6. worker2  เช็ดกระป๋องให้ครบทุกด้าน — ระวังกระป๋องหล่น [Risk: Medium]\\r\\n  7. worker2  เก็บใส่ลัง Good เพื่อส่งกระบวนการถัดไป [Risk: Low]\\r\\nSafety Rules:\\r\\n  - [Critical] กระป๋องหล่น\\r\\n  - [Medium] ไม่ใส่อุปกรณ์ PPE\\r\\n  - [Critical] สายพานหนีบมือ\\r\\n  - [Low] บุคคลอื่นเข้าพื้นที่ทำงาน\\r\\n  - [Medium] วางของที่ไม่เกี่ยวข้องกับงานไว้ในพื้นที่ทำงาน\\r\\n  - [Medium] ทำงานข้ามขั้นตอน ไม่เช็ดกระป๋อง\\r\\n  - [Medium] ทำงานข้ามขั้นตอน ไม่ตรวจสอบด้วยสายตาก่อนนำขึ้นสายพาน\\n\\nIMPORTANT: The SOP above describes exactly what workers SHOULD be doing and what tools/PPE they use. Use it as authoritative reference. Do NOT invent tools or actions not mentioned in the SOP unless clearly visible. When the SOP says a worker uses their eyes for inspection — accept that, do not assume magnifying glass or other tools.\\n\\n=== ANALYSIS TASK ===\\n{\\n  \\"operation\\": {\\n    \\"name\\": \\"Quality Control Station – Can Inspection\\",\\n    \\"description\\": \\"การตรวจสอบคุณภาพกระป๋องด้วยสายตาก่อนส่งต่อกระบวนการถัดไปผ่านสายพานลำเลียง\\",\\n    \\"roles\\": {\\n      \\"Worker1\\": \\"หยิบกระป๋อง ตรวจสอบด้วยสายตา วางกระป๋องดีลงบน conveyor วางกระป๋องเสียลง NG tray\\",\\n      \\"Worker2\\": \\"หยิบกระป๋องออกจาก conveyor เช็ดทุกด้าน แพ็คใส่กล่อง Good\\"\\n    },\\n    \\"ppe_specifications\\": {\\n      \\"helmet\\": {\\n        \\"required\\": true,\\n        \\"acceptable_types\\": [\\n          \\"หมวก safety helmet มาตรฐาน\\",\\n          \\"หมวก cap / แก๊ป\\"\\n        ],\\n        \\"not_acceptable\\": [\\n          \\"ไม่สวมหมวกเลย\\"\\n        ],\\n        \\"how_to_identify\\": \\"สวมอยู่บนศีรษะ ไม่ว่าจะเป็นแบบใดก็ถือว่าผ่าน — ผิดเฉพาะกรณีไม่สวม\\"\\n      },\\n      \\"safety_shoes\\": {\\n        \\"required\\": true,\\n        \\"acceptable_types\\": [\\n          \\"รองเท้านิรภัยหัวเหล็ก EN ISO 20345\\",\\n          \\"รองเท้าหัวเหล็กทั่วไป\\"\\n        ],\\n        \\"not_acceptable\\": [\\n          \\"รองเท้าแตะ\\",\\n          \\"รองเท้าผ้าใบธรรมดา\\",\\n          \\"รองเท้าหนังไม่มีหัวเหล็ก\\",\\n          \\"เท้าเปล่า\\"\\n        ],\\n        \\"how_to_identify\\": \\"รองเท้าหุ้มส้น มีหัวแข็ง ดูหนาและแข็งแรง\\"\\n      },\\n      \\"gloves\\": {\\n        \\"required\\": true,\\n        \\"acceptable_types\\": [\\n          \\"ถุงมือยาง / latex\\",\\n          \\"ถุงมือผ้า\\",\\n          \\"ถุงมือ nitrile\\",\\n          \\"ถุงมือหนัง\\"\\n        ],\\n        \\"not_acceptable\\": [\\n          \\"ไม่สวมถุงมือเลย\\"\\n        ],\\n        \\"how_to_identify\\": \\"มีวัสดุหุ้มมือ ไม่ว่าชนิดใด — ผิดเฉพาะกรณีไม่สวม\\"\\n      },\\n      \\"mask\\": {\\n        \\"required\\": true,\\n        \\"acceptable_types\\": [\\n          \\"หน้ากากอนามัย\\",\\n          \\"N95\\",\\n          \\"หน้ากากผ้า\\"\\n        ],\\n        \\"not_acceptable\\": [\\n          \\"ดึงหน้ากากลงคาง\\",\\n          \\"แขวนหน้ากากที่หู\\",\\n          \\"ไม่สวมเลย\\"\\n        ],\\n        \\"how_to_identify\\": \\"หน้ากากต้องปิดจมูกและปากพร้อมกัน\\"\\n      },\\n      \\"safety_glasses\\": {\\n        \\"required\\": false,\\n        \\"note\\": \\"ต้องการเฉพาะเมื่อใช้สารเคมีทำความสะอาด\\"\\n      },\\n      \\"safety_vest\\": {\\n        \\"required\\": false,\\n        \\"note\\": \\"ไม่จำเป็นในสถานีนี้\\"\\n      }\\n    },\\n    \\"sop_steps\\": [\\n      {\\n        \\"step\\": 1,\\n        \\"title\\": \\"เตรียมพื้นที่ทำงาน\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"ตรวจสอบ NG tray กล่อง Good และ conveyor ให้อยู่ในตำแหน่ง ตรวจสอบว่า conveyor ทำงานได้\\"\\n      },\\n      {\\n        \\"step\\": 2,\\n        \\"title\\": \\"หยิบกระป๋อง\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"Worker1 หยิบกระป๋องทีละใบจากกล่องวัตถุดิบ จับเบาๆ เพื่อไม่ให้บุบ\\"\\n      },\\n      {\\n        \\"step\\": 3,\\n        \\"title\\": \\"ตรวจสอบด้วยสายตา\\",\\n        \\"skippable\\": false,\\n        \\"critical\\": true,\\n        \\"detail\\": \\"ตรวจสอบทุกด้านของกระป๋องภายใต้แสงที่เพียงพอ ตรวจหารอยบุบ สนิม การเสียรูป การปนเปื้อน\\"\\n      },\\n      {\\n        \\"step\\": 4,\\n        \\"title\\": \\"คัดแยกกระป๋อง\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"กระป๋องเสีย → NG tray เท่านั้น กระป๋องดี → วางราบบน conveyor ในตำแหน่งที่กำหนด\\",\\n        \\"hazard\\": \\"Conveyor หนีบมือ\\",\\n        \\"hazard_severity\\": \\"HIGH\\"\\n      },\\n      {\\n        \\"step\\": 5,\\n        \\"title\\": \\"สแกนด้วย AI camera\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"conveyor เลื่อนกระป๋องผ่านกล้อง AI เพื่อตรวจสอบอัตโนมัติ\\"\\n      },\\n      {\\n        \\"step\\": 6,\\n        \\"title\\": \\"หยิบกระป๋องออกจาก conveyor\\",\\n        \\"skippable\\": false,\\n        \\"critical\\": true,\\n        \\"detail\\": \\"Worker2 หยิบกระป๋องที่ออกมาพ้นสายพานแล้ว หรือรอให้ conveyor หยุดก่อน — การหยิบกระป๋องที่ปลาย conveyor ในตำแหน่งรับของที่กำหนดถือเป็นการทำงานปกติ ผิดเฉพาะกรณีที่มือเข้าไปใน belt area ที่กำลังเคลื่อนที่\\",\\n        \\"hazard\\": \\"Conveyor หนีบมือ\\",\\n        \\"hazard_severity\\": \\"HIGH\\"\\n      },\\n      {\\n        \\"step\\": 7,\\n        \\"title\\": \\"เช็ดกระป๋อง\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"เช็ดทุกด้าน (บน ข้าง ล่าง) ด้วยผ้าสะอาดก่อนแพ็ค\\",\\n        \\"hazard\\": \\"กระป๋องหล่น\\",\\n        \\"hazard_severity\\": \\"MEDIUM\\"\\n      },\\n      {\\n        \\"step\\": 8,\\n        \\"title\\": \\"แพ็คใส่กล่อง Good\\",\\n        \\"skippable\\": false,\\n        \\"detail\\": \\"วางกระป๋องเรียบร้อยในกล่อง Good ห้ามวางเกินความสูงที่กำหนด\\"\\n      }\\n    ],\\n    \\"inspection_criteria\\": {\\n      \\"purpose\\": \\"เกณฑ์ตัดสินมาตรฐานสำหรับ Worker1 ในการคัดแยกกระป๋อง Good vs NG\\",\\n      \\"defect_types\\": {\\n        \\"dent\\": {\\n          \\"name\\": \\"รอยบุบ\\",\\n          \\"pass\\": \\"รอยบุบเล็กน้อยที่ไม่กระทบรูปทรงโดยรวม ขนาด < 3 mm และไม่อยู่บริเวณขอบหรือฝากระป๋อง\\",\\n          \\"ng\\": \\"รอยบุบลึกหรือกว้าง >= 3 mm, รอยบุบบริเวณขอบหรือฝา, รอยบุบที่ทำให้กระป๋องเสียรูปทรง\\",\\n          \\"severity\\": \\"HIGH\\"\\n        },\\n        \\"rust\\": {\\n          \\"name\\": \\"สนิม\\",\\n          \\"pass\\": \\"ไม่มีสนิมใดๆ\\",\\n          \\"ng\\": \\"พบจุดสนิมหรือคราบสีน้ำตาล/แดงใดๆ บนผิวกระป๋อง ไม่ว่าขนาดเล็กเพียงใด\\",\\n          \\"severity\\": \\"HIGH\\"\\n        },\\n        \\"deformation\\": {\\n          \\"name\\": \\"การเสียรูป\\",\\n          \\"pass\\": \\"กระป๋องทรงกระบอกตรง ปิดฝาได้สนิท\\",\\n          \\"ng\\": \\"กระป๋องบิดเบี้ยว บวม โป่ง หรือฝาปิดไม่สนิท\\",\\n          \\"severity\\": \\"CRITICAL\\"\\n        },\\n        \\"contamination\\": {\\n          \\"name\\": \\"การปนเปื้อน\\",\\n          \\"pass\\": \\"ผิวกระป๋องสะอาด ไม่มีสิ่งแปลกปลอม\\",\\n          \\"ng\\": \\"พบคราบน้ำมัน สารเคมี สิ่งสกปรก หรือวัตถุแปลกปลอมติดผิวกระป๋อง\\",\\n          \\"severity\\": \\"HIGH\\"\\n        },\\n        \\"scratch\\": {\\n          \\"name\\": \\"รอยขีดข่วน\\",\\n          \\"pass\\": \\"รอยขีดตื้นที่ไม่ทะลุผิวเคลือบ\\",\\n          \\"ng\\": \\"รอยขีดที่ทะลุผิวเคลือบจนเห็นเนื้อโลหะ หรือรอยยาวต่อเนื่อง > 10 mm\\",\\n          \\"severity\\": \\"MEDIUM\\"\\n        },\\n        \\"label_defect\\": {\\n          \\"name\\": \\"ฉลาก/พิมพ์ผิดปกติ\\",\\n          \\"pass\\": \\"ตัวอักษรและโลโก้ชัดเจน ไม่เบี้ยว\\",\\n          \\"ng\\": \\"ฉลากเบี้ยว ลอก หรือตัวอักษรไม่ชัดเจน\\",\\n          \\"severity\\": \\"MEDIUM\\"\\n        },\\n        \\"opening\\": {\\n          \\"name\\": \\"ฝา/ช่องเปิด\\",\\n          \\"pass\\": \\"ฝาอยู่ในตำแหน่งปกติ ไม่มีการเปิดบางส่วน\\",\\n          \\"ng\\": \\"ฝาเปิดอยู่บางส่วน ฝาหลุด หรือซีลขาด\\",\\n          \\"severity\\": \\"CRITICAL\\"\\n        }\\n      },\\n      \\"inspection_method\\": [\\n        \\"หมุนกระป๋อง 360° เพื่อตรวจทุกด้าน\\",\\n        \\"ตรวจด้านบน (ฝา) และด้านล่าง (ก้น) ด้วย\\",\\n        \\"ตรวจภายใต้แสงสว่างที่เพียงพอเสมอ\\",\\n        \\"หากสงสัยให้จัดเป็น NG ก่อน แจ้ง Supervisor ตรวจซ้ำ\\"\\n      ],\\n      \\"ng_rate_threshold\\": {\\n        \\"warning\\": \\"NG > 10% ใน 1 ชั่วโมง → แจ้ง Supervisor ทันที\\",\\n        \\"stop_line\\": \\"NG > 20% ใน 1 ชั่วโมง → หยุดสายการผลิต รอการตรวจสอบจาก Supervisor\\",\\n        \\"warning_severity\\": \\"MEDIUM\\",\\n        \\"stop_line_severity\\": \\"HIGH\\"\\n      }\\n    },\\n    \\"step_sequence_rules\\": {\\n      \\"must_follow_order\\": true,\\n      \\"critical_steps\\": [\\n        3,\\n        6\\n      ],\\n      \\"skip_severity\\": {\\n        \\"step_3\\": \\"MEDIUM — ข้ามการตรวจสอบด้วยสายตา กระป๋องเสียอาจผ่านไปสายพาน\\",\\n        \\"step_6\\": \\"CRITICAL — หยิบกระป๋องขณะสายพานยังวิ่ง เสี่ยงมือติดสายพาน\\",\\n        \\"step_7\\": \\"MEDIUM — ไม่เช็ดกระป๋อง คุณภาพสินค้าต่ำลง\\",\\n        \\"other_steps\\": \\"LOW — เบี่ยงเบนจาก SOP เล็กน้อย\\"\\n      },\\n      \\"out_of_order_severity\\": \\"MEDIUM\\",\\n      \\"rushing_signs\\": [\\n        \\"Worker1 วางกระป๋องลง conveyor โดยไม่หยุดตรวจสอบ\\",\\n        \\"Worker2 หยิบกระป๋องออกก่อนที่จะออกจากสายพาน\\",\\n        \\"ข้ามขั้นตอนเช็ดกระป๋องเพื่อเร่งความเร็ว\\"\\n      ]\\n    },\\n    \\"personnel_management\\": {\\n      \\"authorized_roles\\": {\\n        \\"Worker1\\": {\\n          \\"zone_access\\": \\"เต็มพื้นที่\\",\\n          \\"ppe_required\\": \\"ครบทุกชิ้น\\"\\n        },\\n        \\"Worker2\\": {\\n          \\"zone_access\\": \\"เต็มพื้นที่\\",\\n          \\"ppe_required\\": \\"ครบทุกชิ้น\\"\\n        },\\n        \\"Supervisor\\": {\\n          \\"zone_access\\": \\"เข้าได้ตรวจสอบ ห้ามแทรกแซงการทำงาน\\",\\n          \\"ppe_required\\": \\"รองเท้านิรภัยและหมวกอย่างน้อย\\",\\n          \\"max_duration\\": \\"ไม่จำกัด\\",\\n          \\"severity_if_no_ppe\\": \\"MEDIUM\\"\\n        },\\n        \\"Maintenance\\": {\\n          \\"zone_access\\": \\"เข้าได้เฉพาะเมื่อ conveyor หยุดและมี Work Permit\\",\\n          \\"ppe_required\\": \\"ครบทุกชิ้นตามงาน\\",\\n          \\"severity_if_enter_during_operation\\": \\"HIGH\\"\\n        }\\n      },\\n      \\"cross_zone_worker\\": {\\n        \\"definition\\": \\"พนักงานจาก zone อื่นเข้ามาแจ้งงานหรือส่งของ\\",\\n        \\"allowed\\": true,\\n        \\"conditions\\": [\\n          \\"ต้องอยู่นอก boundary line ของสถานีทำงาน\\",\\n          \\"ต้องสวมรองเท้านิรภัยอย่างน้อย\\",\\n          \\"ห้ามสัมผัสกระป๋องหรืออุปกรณ์\\",\\n          \\"ระยะเวลาไม่เกิน 2 นาที\\",\\n          \\"ห้ามส่งอาหาร เครื่องดื่ม หรือสิ่งของส่วนตัวเข้ามาในพื้นที่ปฏิบัติงาน\\"\\n        ],\\n        \\"severity_if_violate\\": \\"MEDIUM\\"\\n      },\\n      \\"unauthorized_person\\": {\\n        \\"definition\\": \\"บุคคลที่ไม่มีธุระในพื้นที่ เช่น บุคคลภายนอก ผู้เยี่ยมชมที่ไม่มี escort\\",\\n        \\"allowed\\": false,\\n        \\"immediate_response\\": [\\n          \\"Worker หยุดงานทันที\\",\\n          \\"แจ้งให้บุคคลออกจากพื้นที่\\",\\n          \\"แจ้ง Supervisor ทันที\\",\\n          \\"กลับทำงานเมื่อพื้นที่ปลอดภัยแล้วเท่านั้น\\"\\n        ],\\n        \\"severity\\": \\"LOW\\"\\n      },\\n      \\"person_count_alert\\": {\\n        \\"normal\\": 2,\\n        \\"alert_if_more_than\\": 3,\\n        \\"alert_severity\\": \\"MEDIUM\\"\\n      }\\n    },\\n    \\"incident_types\\": {\\n      \\"near_miss\\": {\\n        \\"definition\\": \\"เหตุการณ์ที่เกือบเกิดอุบัติเหตุแต่ไม่มีการบาดเจ็บ\\",\\n        \\"examples\\": [\\n          \\"มือเกือบโดน conveyor แต่ดึงออกทัน\\",\\n          \\"กระป๋องเกือบตกแต่รับทัน\\",\\n          \\"สะดุดแต่ไม่ล้ม\\",\\n          \\"กระป๋องเกือบหล่นใส่เท้า\\"\\n        ],\\n        \\"severity\\": \\"HIGH\\",\\n        \\"required_action\\": \\"หยุดงาน รายงาน Supervisor ทันที บันทึก Near-Miss Report\\"\\n      },\\n      \\"property_damage\\": {\\n        \\"definition\\": \\"อุปกรณ์หรือสินค้าเสียหาย\\",\\n        \\"examples\\": [\\n          \\"กระป๋องตกพื้น\\",\\n          \\"กล่อง Good ล้ม\\",\\n          \\"NG tray ล้น\\"\\n        ],\\n        \\"severity\\": \\"CRITICAL\\",\\n        \\"required_action\\": \\"หยุดงาน เก็บของที่ตก แจ้ง Supervisor\\"\\n      },\\n      \\"minor_injury\\": {\\n        \\"definition\\": \\"บาดเจ็บเล็กน้อย\\",\\n        \\"examples\\": [\\n          \\"บาดมือจากขอบกระป๋อง\\",\\n          \\"ของตกใส่เท้า\\",\\n          \\"ลื่นล้มเล็กน้อย\\"\\n        ],\\n        \\"severity\\": \\"HIGH\\",\\n        \\"required_action\\": \\"หยุดงานทันที ปฐมพยาบาล แจ้ง Supervisor บันทึก Incident Report\\"\\n      },\\n      \\"major_injury\\": {\\n        \\"definition\\": \\"บาดเจ็บสาหัส\\",\\n        \\"examples\\": [\\n          \\"มือติด conveyor\\",\\n          \\"ล้มศีรษะกระแทก\\",\\n          \\"หมดสติ\\"\\n        ],\\n        \\"severity\\": \\"CRITICAL\\",\\n        \\"required_action\\": [\\n          \\"กดปุ่ม Emergency Stop ทันที\\",\\n          \\"โทร 1669 หรือหน่วยฉุกเฉินโรงงาน\\",\\n          \\"ห้ามเคลื่อนย้ายผู้บาดเจ็บจนกว่าทีมแพทย์จะมาถึง\\",\\n          \\"แจ้ง Supervisor และ Safety Officer ทันที\\",\\n          \\"ห้ามเดินเครื่องจนกว่าจะได้รับอนุญาต\\"\\n        ]\\n      }\\n    },\\n    \\"hygiene_rules\\": {\\n      \\"purpose\\": \\"ป้องกันการปนเปื้อนในผลิตภัณฑ์\\",\\n      \\"rules\\": [\\n        \\"ห้ามสัมผัสหน้า ผม หู จมูก ปาก ขณะสวมถุงมือที่ใช้จับกระป๋อง\\",\\n        \\"หากสัมผัสหน้า ต้องเปลี่ยนถุงมือใหม่ก่อนหยิบกระป๋องต่อ\\",\\n        \\"กระป๋องที่ตกพื้นถือว่าเป็น NG ต้องใส่ NG tray เสมอ ห้ามหยิบขึ้นมาใช้\\",\\n        \\"ถุงมือขาดหรือสกปรกต้องเปลี่ยนทันที\\",\\n        \\"ห้ามรับประทานอาหารหรือดื่มน้ำในพื้นที่ทำงาน\\",\\n        \\"Worker2 ต้องเช็ดกระป๋องครบทุกด้าน (บน ข้าง ล่าง) ห้ามข้ามด้านใดด้านหนึ่ง\\",\\n        \\"ห้ามรับอาหาร เครื่องดื่ม หรือสิ่งของส่วนตัวจากบุคคลภายนอกขณะปฏิบัติงานในพื้นที่\\"\\n      ],\\n      \\"violation_severity\\": \\"MEDIUM\\"\\n    },\\n    \\"ergonomics_rules\\": {\\n      \\"purpose\\": \\"ป้องกันการบาดเจ็บจากการทำงานซ้ำๆ และท่าทางที่ไม่ถูกต้อง\\",\\n      \\"normal_posture_note\\": \\"การก้มตัวเล็กน้อยเพื่อหยิบกระป๋องเป็นเรื่องปกติของงานนี้ ไม่ต้อง flag\\",\\n      \\"flag_only_when\\": [\\n        \\"ก้มหลังอย่างรุนแรง (หลังขนานพื้น) ซ้ำๆ ติดต่อกันหลายครั้ง\\",\\n        \\"บิดเอวขณะถือกระป๋อง\\",\\n        \\"แสดงอาการเจ็บปวดชัดเจน เช่น จับหลัง หยุดพักบ่อยผิดปกติ\\",\\n        \\"ท่าทางแย่ลงเรื่อยๆ เห็นได้ชัดตลอดวิดีโอ\\"\\n      ],\\n      \\"do_not_flag\\": [\\n        \\"การก้มเล็กน้อยเพื่อหยิบกระป๋อง 1-2 ครั้ง\\",\\n        \\"ท่าทางปกติของงาน QC\\",\\n        \\"การเอื้อมมือไปข้างหน้าในระยะสั้น\\"\\n      ],\\n      \\"severity_guide\\": {\\n        \\"severe_repeated_bending\\": \\"LOW\\",\\n        \\"twisting_with_load\\": \\"MEDIUM\\",\\n        \\"visible_pain_signs\\": \\"MEDIUM\\"\\n      }\\n    },\\n    \\"behavior_rules\\": {\\n      \\"focus_requirements\\": [\\n        \\"ห้ามใช้โทรศัพท์มือถือขณะปฏิบัติงาน\\",\\n        \\"ห้ามคุยกันในลักษณะที่เสียสมาธิจากการตรวจสอบ\\",\\n        \\"ห้ามฟังเพลงหรือสวมหูฟังขณะทำงาน\\"\\n      ],\\n      \\"behavior_violations\\": {\\n        \\"phone_use\\": {\\n          \\"severity\\": \\"MEDIUM\\",\\n          \\"description\\": \\"ใช้โทรศัพท์ขณะทำงาน\\"\\n        },\\n        \\"distracted_talk\\": {\\n          \\"severity\\": \\"LOW\\",\\n          \\"description\\": \\"คุยกันเกินความจำเป็น\\"\\n        },\\n        \\"rushing\\": {\\n          \\"severity\\": \\"HIGH\\",\\n          \\"description\\": \\"ทำงานเร็วเกินจนข้ามขั้นตอนตรวจ\\"\\n        },\\n        \\"fatigue_visible\\": {\\n          \\"severity\\": \\"LOW\\",\\n          \\"description\\": \\"แสดงอาการเมื่อยล้าชัดเจน\\"\\n        }\\n      }\\n    },\\n    \\"conveyor_rules\\": [\\n      \\"ห้ามเอื้อมมือเข้าไปใน conveyor ที่กำลังวิ่ง\\",\\n      \\"วางกระป๋องในตำแหน่งและทิศทางที่กำหนดบน conveyor เท่านั้น\\",\\n      \\"หาก conveyor ติดขัด ให้หยุดเครื่องก่อนแก้ไขเสมอ\\",\\n      \\"กระป๋องที่สะสมบน conveyor มากเกินไปต้องรายงาน Supervisor\\",\\n      \\"ห้ามวางสิ่งของอื่นบน conveyor นอกจากกระป๋องที่ผ่านการตรวจแล้ว\\",\\n      \\"ห้าม Worker1/Worker2 ปรับ ซ่อม หรือถอดชิ้นส่วนสายพานเอง — ให้หยุดเครื่อง รายงาน Supervisor และรอ Maintenance ดำเนินการ\\"\\n    ],\\n    \\"prohibited_actions\\": [\\n      \\"เอื้อมมือเข้า conveyor ที่กำลังวิ่ง (CRITICAL)\\",\\n      \\"หยิบกระป๋องขณะ conveyor ยังทำงาน (CRITICAL)\\",\\n      \\"ใส่กระป๋อง NG ลงกล่อง Good (HIGH)\\",\\n      \\"ข้ามขั้นตอนการตรวจสอบด้วยสายตา (HIGH)\\",\\n      \\"วางกระป๋องที่ตกพื้นกลับเข้า Good (MEDIUM)\\",\\n      \\"ใช้โทรศัพท์ขณะปฏิบัติงาน (MEDIUM)\\",\\n      \\"บุคคลที่ไม่เกี่ยวข้องเข้าพื้นที่โดยไม่มี escort (LOW)\\",\\n      \\"ทำงานโดยไม่สวม PPE ครบ (MEDIUM)\\",\\n      \\"วางของที่ไม่เกี่ยวข้องกับงานไว้ในพื้นที่ทำงาน (MEDIUM)\\",\\n      \\"รับอาหารหรือเครื่องดื่มจากบุคคลภายนอกในพื้นที่ทำงาน (MEDIUM)\\",\\n      \\"Worker ปรับหรือซ่อมสายพานด้วยตนเองโดยไม่มี Maintenance (HIGH)\\"\\n    ],\\n    \\"unsafe_conditions\\": [\\n      \\"พื้นเปียกหรือลื่น\\",\\n      \\"กระป๋องกระจายบนพื้น (เสี่ยงสะดุด/ลื่น)\\",\\n      \\"แสงสว่างไม่เพียงพอสำหรับการตรวจสอบด้วยสายตา\\",\\n      \\"conveyor ขัดข้อง ติดขัด หรือวิ่งเร็วผิดปกติ\\",\\n      \\"NG tray เต็มเกินไป (เสี่ยงล้น)\\",\\n      \\"พื้นที่รก ไม่เป็นระเบียบ (5S ไม่ผ่าน)\\",\\n      \\"มีสิ่งของที่ไม่เกี่ยวข้องกับงาน (เช่น อาหาร เครื่องดื่ม ของส่วนตัว) วางในพื้นที่ทำงาน\\"\\n    ],\\n    \\"safe_practices\\": [\\n      \\"รักษาพื้นที่ทำงานให้สะอาดและเป็นระเบียบ (5S)\\",\\n      \\"รายงานความผิดปกติของ conveyor ต่อ Supervisor ทันที\\",\\n      \\"ไม่เร่งรีบตรวจสอบ — คุณภาพสำคัญกว่าความเร็ว\\",\\n      \\"เปลี่ยนถุงมือเมื่อขาดหรือสกปรก\\",\\n      \\"บันทึก Near-Miss ทุกครั้งแม้ไม่มีการบาดเจ็บ\\"\\n    ]\\n  }\\n}\\n\\nCompare what you observe in these frames against the SOP above. Highlight any DEVIATIONS from the SOP procedure, missing PPE, or unsafe conditions relative to the defined safety rules."}, "latency_ms": 229228, "prompt_name": "General Safety Monitoring", "total_frames": 7}
\.


--
-- Data for Name: safety_rule_items; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.safety_rule_items (id, rule_set_id, category, rule_text, rule_text_th, severity, is_prohibited, sort_order, sub_section) FROM stdin;
1	1	general	Must wear full PPE before entering area	ต้องสวม PPE ครบถ้วนก่อนเข้าพื้นที่ (Safety Shoes, Safety Vest)	medium	f	1	\N
2	1	general	Only trained personnel may operate Forklift	อนุญาตเฉพาะผู้ที่ได้รับการอบรมเท่านั้นในการใช้งาน Forklift	high	f	2	\N
3	1	general	Unauthorized persons prohibited in work area	ห้ามผู้ที่ไม่เกี่ยวข้องเข้าในพื้นที่ปฏิบัติงาน	high	t	3	\N
4	1	general	Maintain 5S cleanliness in work area	ต้องรักษาความสะอาดและความเป็นระเบียบของพื้นที่ (5S)	medium	f	4	\N
5	1	before	Inspect Forklift condition before every use	ต้องตรวจสอบสภาพ Forklift ทุกครั้งก่อนใช้งาน	high	f	1	\N
6	1	before	Verify work area is clear of obstructions	ต้องตรวจสอบพื้นที่ให้ปลอดภัย ไม่มีสิ่งกีดขวาง	high	f	2	\N
7	1	before	Verify roll material is in good condition	ต้องตรวจสอบม้วนวัสดุให้อยู่ในสภาพพร้อมใช้งาน	medium	f	3	\N
8	1	before	Do not start work if equipment is defective	ห้ามเริ่มงานหากพบอุปกรณ์ชำรุด	critical	t	4	\N
14	1	prohibited	Never stand in front of roll material (Danger Zone)	ห้ามยืนด้านหน้าม้วนวัสดุ (Danger Zone)	critical	t	1	\N
15	1	prohibited	Never touch roll material while moving	ห้ามจับม้วนวัสดุขณะเคลื่อนที่	critical	t	2	\N
16	1	prohibited	Never drive Forklift at high speed	ห้ามขับ Forklift ด้วยความเร็วสูง	critical	t	3	\N
17	1	prohibited	Never use uninspected Forklift	ห้ามใช้งาน Forklift ที่ไม่ได้รับการตรวจสอบ	high	t	4	\N
18	1	prohibited	Never operate without authorization	ห้ามใช้งานโดยไม่ได้รับอนุญาต	high	t	5	\N
19	1	unsafe_condition	Slippery/wet floor	พื้นลื่น / เปียก	high	f	1	\N
20	1	unsafe_condition	Narrow area / obstructed path	พื้นที่แคบ / มีสิ่งกีดขวาง	high	f	2	\N
21	1	unsafe_condition	Roll not securely fastened to shaft	ม้วนวัสดุไม่ยึดแน่นกับแกน	critical	f	3	\N
22	1	unsafe_condition	Insufficient lighting	แสงสว่างไม่เพียงพอ	medium	f	4	\N
23	1	safe_practice	Use hand signals or voice for communication	ใช้สัญญาณมือหรือเสียงในการสื่อสาร	medium	f	1	\N
24	1	safe_practice	Check safety at every step	ตรวจสอบความปลอดภัยทุกขั้นตอน	high	f	2	\N
25	1	safe_practice	Maintain distance from Forklift and load	รักษาระยะห่างจาก Forklift และ Load	high	f	3	\N
26	1	safe_practice	Follow SOP strictly	ปฏิบัติตาม SOP อย่างเคร่งครัด	high	f	4	\N
27	1	critical	Absolutely no persons in Danger Zone	ห้ามมีคนอยู่ใน Danger Zone โดยเด็ดขาด	critical	t	1	\N
28	1	critical	Must control Forklift speed at all times	ต้องควบคุมความเร็ว Forklift ตลอดเวลา	critical	f	2	\N
29	1	critical	Must verify load stability before moving	ต้องตรวจสอบความมั่นคงของ Load ก่อนเคลื่อนย้าย	critical	f	3	\N
30	1	critical	Safety always before Productivity	Safety มาก่อน Productivity เสมอ	critical	f	4	\N
31	1	during	Must drive Forklift at low speed	ต้องขับ Forklift ด้วยความเร็วต่ำ	high	f	1	3.1
32	1	during	Must approach roll material in straight alignment	ต้องเข้าหาม้วนวัสดุอย่างตรงแนว	medium	f	2	3.1
33	1	during	Never impact material	ห้ามกระแทกวัสดุ	high	t	3	3.1
34	1	during	Must insert rod at center of roll	ต้องใส่แกนให้ตรงศูนย์กลางของม้วนวัสดุ	critical	f	4	3.2
35	1	during	Helper must stand to the side only	Helper ต้องอยู่ด้านข้างเท่านั้น	critical	f	5	3.2
36	1	during	Never place hands near pinch points	ห้ามวางมือใกล้จุดหนีบ	critical	t	6	3.2
37	1	during	Must lift slowly and in a controlled manner	ต้องยกขึ้นอย่างช้าและควบคุมได้	high	f	7	3.3
38	1	during	Must check balance before moving	ต้องตรวจสอบความสมดุลก่อนเคลื่อนย้าย	critical	f	8	3.3
39	1	during	Never lift higher than necessary	ห้ามยกสูงเกินความจำเป็น	high	t	9	3.3
40	1	during	Must use low speed	ต้องใช้ความเร็วต่ำ	high	f	10	3.4
41	1	during	Helper must walk alongside to give signals	ต้องมี Helper เดินข้างเพื่อให้สัญญาณ	high	f	11	3.4
42	1	during	Never have anyone in front of roll material	ห้ามมีบุคคลอยู่ด้านหน้าม้วนวัสดุ	critical	t	12	3.4
43	1	during	Must maintain at least 1-2 meters distance	ต้องรักษาระยะห่างอย่างน้อย 1–2 เมตร	high	f	13	3.4
44	1	during	Must lower slowly	ต้องลดระดับลงอย่างช้า	high	f	14	3.5
45	1	during	Must place in designated position	ต้องวางในตำแหน่งที่กำหนด	medium	f	15	3.5
46	1	during	Must verify stability before release	ต้องตรวจสอบความมั่นคงก่อนปล่อย	critical	f	16	3.5
47	1	during	Must withdraw rod carefully	ต้องถอนแกนอย่างระมัดระวัง	high	f	17	3.6
48	1	during	Must reverse Forklift safely	ต้องถอย Forklift อย่างปลอดภัย	high	f	18	3.6
49	1	during	Must store equipment properly	ต้องจัดเก็บอุปกรณ์ให้เรียบร้อย	medium	f	19	3.6
\.


--
-- Data for Name: safety_rule_sets; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.safety_rule_sets (id, process_id, title, title_th, version, active, created_at) FROM stdin;
1	1	Safety Rules: Forklift Roll Handling	กฎความปลอดภัย: การปฏิบัติงานโกดัง Forklift Roll Handling	1.0	t	2026-03-21 07:44:52.340759+00
\.


--
-- Data for Name: safety_rules; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.safety_rules (id, category, description, severity, active, created_at) FROM stdin;
\.


--
-- Data for Name: sop_steps; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.sop_steps (id, sop_id, step_no, description, title, title_th, is_critical) FROM stdin;
425	5	1		ตรวจสอบ Forklift และพื้นที่ปฏิบัติงาน	\N	f
426	5	2		สวม PPE ให้ครบถ้วนก่อนเข้าพื้นที่	\N	t
427	5	3		ขับ Forklift เข้าหาม้วนวัสดุด้วยความเร็วต่ำ	\N	f
418	4	1		กระป๋องรอเข้ากระกวนการตรวจสอบคุณภาพถูกวางอยู่ในลัง	Low	f
419	4	2		worker1  หยิบกระป๋องเเละตรวจสอบด้วยสายตา หากพบกระป๋องผิดปกติให้หยิบออกใส่ถาด NG	Low	f
420	4	3	ระวัง Conveyor หนีบมือ	worker1  วางกระป๋องที่สภาพดีลงบน conveyer 	High	f
421	4	4		Conveyour เลื่อนกระป๋องผ่านกล้องเพื่อถ่ายรูปกระป๋องและตรวจสอบด้วย AI 	Low	f
422	4	5	ระวัง Conveyor หนีบมือ	worker2  หยิบกระป๋องออกจาก conveyor	High	f
423	4	6	ระวังกระป๋องหล่น	worker2  เช็ดกระป๋องให้ครบทุกด้าน	Medium	f
424	4	7		worker2  เก็บใส่ลัง Good เพื่อส่งกระบวนการถัดไป	Low	f
\.


--
-- Data for Name: sops; Type: TABLE DATA; Schema: public; Owner: ssg
--

COPY public.sops (id, code, title, category, status, version, created_at, process_id, title_th, purpose, responsible, equipment, kpi, active, safety_rules) FROM stdin;
4	SOP-002	Production Line	\N	published	v1.15	2026-03-21 11:21:32.062998+00	2	\N	Add Safety Rules	Thongpan.S	["ถุงมือผ้า","หน้ากากอนามัย","หมวกcap","รองเท้า Safety"]	[{"ver":"v1.15","note":"Add Safety Rules","by":"User","date":"2026-03-22","type":"add"},{"ver":"v1.14","note":"Add Safety Rules","by":"User","date":"2026-03-22","type":"add"},{"ver":"v1.13","note":"Add Safety Rules","by":"User","date":"2026-03-22","type":"add"},{"ver":"v1.12","note":"Add Safety Shoes","by":"User","date":"2026-03-22","type":"add"},{"ver":"v1.11","note":"Revise PPE","by":"User","date":"2026-03-22","type":"add"},{"ver":"v1.10","note":"Revise worker","by":"User","date":"2026-03-21","type":"add"},{"ver":"v1.9","note":"Add Safety Rule","by":"User","date":"2026-03-21","type":"add"},{"ver":"v1.8","note":"Add Safety Rule","by":"User","date":"2026-03-21","type":"add"},{"ver":"v1.7","note":"Chage Risk level","by":"User","date":"2026-03-21","type":"add"},{"ver":"v1.6","note":"Add PPE List","by":"User","date":"2026-03-21","type":"add"},{"ver":"v1.5","note":"Add PPE List","by":"User","date":"2026-03-21","type":"add"},{"ver":"v1.4","note":"Add PPE List","by":"User","date":"2026-03-21","type":"add"},{"ver":"v1.3","note":"Add PPE List","by":"User","date":"2026-03-21","type":"add"},{"ver":"v1.2","note":"Add PPE List","by":"User","date":"2026-03-21","type":"add"}]	t	[{"id":1774096367166,"text":"กระป๋องหล่น","severity":"Critical","category":"nearmiss"},{"id":1774096381263,"text":"ไม่ใส่อุปกรณ์ PPE","severity":"Medium","category":"action"},{"id":1774096397320,"text":"สายพานหนีบมือ","severity":"Critical","category":"nearmiss"},{"id":1774096426315,"text":"บุคคลอื่นเข้าพื้นที่ทำงาน","severity":"Low","category":"action"},{"id":1774173370240,"text":"วางของที่ไม่เกี่ยวข้องกับงานไว้ในพื้นที่ทำงาน","severity":"Medium","category":"action"},{"id":1774173480233,"text":"ทำงานข้ามขั้นตอน ไม่เช็ดกระป๋อง","severity":"Medium","category":"action"},{"id":1774173527565,"text":"ทำงานข้ามขั้นตอน ไม่ตรวจสอบด้วยสายตาก่อนนำขึ้นสายพาน","severity":"Medium","category":"action"}]
5	SOP-003	Folklift Store	\N	draft	1.0	2026-03-22 13:02:26.067576+00	1	\N	\N	Thongpan.S	["Helmet","Safety Vest","Safety Shoes","Gloves"]	\N	t	\N
\.


--
-- Name: alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.alerts_id_seq', 8, true);


--
-- Name: analysis_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.analysis_jobs_id_seq', 13, true);


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.events_id_seq', 210, true);


--
-- Name: frame_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.frame_results_id_seq', 174, true);


--
-- Name: media_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.media_files_id_seq', 152, true);


--
-- Name: processes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.processes_id_seq', 2, true);


--
-- Name: prompts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.prompts_id_seq', 7, true);


--
-- Name: safety_rule_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.safety_rule_items_id_seq', 49, true);


--
-- Name: safety_rule_sets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.safety_rule_sets_id_seq', 1, true);


--
-- Name: safety_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.safety_rules_id_seq', 1, false);


--
-- Name: sop_steps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.sop_steps_id_seq', 427, true);


--
-- Name: sops_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ssg
--

SELECT pg_catalog.setval('public.sops_id_seq', 5, true);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: analysis_jobs analysis_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.analysis_jobs
    ADD CONSTRAINT analysis_jobs_pkey PRIMARY KEY (id);


--
-- Name: cameras cameras_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.cameras
    ADD CONSTRAINT cameras_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: frame_results frame_results_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.frame_results
    ADD CONSTRAINT frame_results_pkey PRIMARY KEY (id);


--
-- Name: media_files media_files_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_pkey PRIMARY KEY (id);


--
-- Name: processes processes_code_key; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.processes
    ADD CONSTRAINT processes_code_key UNIQUE (code);


--
-- Name: processes processes_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.processes
    ADD CONSTRAINT processes_pkey PRIMARY KEY (id);


--
-- Name: prompts prompts_code_key; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.prompts
    ADD CONSTRAINT prompts_code_key UNIQUE (code);


--
-- Name: prompts prompts_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.prompts
    ADD CONSTRAINT prompts_pkey PRIMARY KEY (id);


--
-- Name: safety_rule_items safety_rule_items_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.safety_rule_items
    ADD CONSTRAINT safety_rule_items_pkey PRIMARY KEY (id);


--
-- Name: safety_rule_sets safety_rule_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.safety_rule_sets
    ADD CONSTRAINT safety_rule_sets_pkey PRIMARY KEY (id);


--
-- Name: safety_rules safety_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.safety_rules
    ADD CONSTRAINT safety_rules_pkey PRIMARY KEY (id);


--
-- Name: sop_steps sop_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.sop_steps
    ADD CONSTRAINT sop_steps_pkey PRIMARY KEY (id);


--
-- Name: sops sops_code_key; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_code_key UNIQUE (code);


--
-- Name: sops sops_pkey; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_pkey PRIMARY KEY (id);


--
-- Name: sop_steps uq_sop_steps_sop_step; Type: CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.sop_steps
    ADD CONSTRAINT uq_sop_steps_sop_step UNIQUE (sop_id, step_no);


--
-- Name: idx_alerts_severity; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_alerts_severity ON public.alerts USING btree (severity);


--
-- Name: idx_alerts_status; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_alerts_status ON public.alerts USING btree (status);


--
-- Name: idx_events_camera; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_events_camera ON public.events USING btree (camera_id);


--
-- Name: idx_events_occurred; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_events_occurred ON public.events USING btree (occurred_at DESC);


--
-- Name: idx_jobs_process; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_jobs_process ON public.analysis_jobs USING btree (process_id);


--
-- Name: idx_media_event; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_media_event ON public.media_files USING btree (event_id);


--
-- Name: idx_rule_items_category; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_rule_items_category ON public.safety_rule_items USING btree (category);


--
-- Name: idx_rule_items_set; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_rule_items_set ON public.safety_rule_items USING btree (rule_set_id);


--
-- Name: idx_rule_sets_process; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_rule_sets_process ON public.safety_rule_sets USING btree (process_id);


--
-- Name: idx_sop_steps_sop; Type: INDEX; Schema: public; Owner: ssg
--

CREATE INDEX idx_sop_steps_sop ON public.sop_steps USING btree (sop_id);


--
-- Name: alerts alerts_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES public.cameras(id);


--
-- Name: alerts alerts_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: analysis_jobs analysis_jobs_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.analysis_jobs
    ADD CONSTRAINT analysis_jobs_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES public.cameras(id);


--
-- Name: analysis_jobs analysis_jobs_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.analysis_jobs
    ADD CONSTRAINT analysis_jobs_process_id_fkey FOREIGN KEY (process_id) REFERENCES public.processes(id);


--
-- Name: analysis_jobs analysis_jobs_rule_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.analysis_jobs
    ADD CONSTRAINT analysis_jobs_rule_set_id_fkey FOREIGN KEY (rule_set_id) REFERENCES public.safety_rule_sets(id);


--
-- Name: analysis_jobs analysis_jobs_sop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.analysis_jobs
    ADD CONSTRAINT analysis_jobs_sop_id_fkey FOREIGN KEY (sop_id) REFERENCES public.sops(id);


--
-- Name: events events_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES public.cameras(id);


--
-- Name: frame_results frame_results_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.frame_results
    ADD CONSTRAINT frame_results_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES public.cameras(id);


--
-- Name: frame_results frame_results_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.frame_results
    ADD CONSTRAINT frame_results_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: frame_results frame_results_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.frame_results
    ADD CONSTRAINT frame_results_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.analysis_jobs(id) ON DELETE CASCADE;


--
-- Name: media_files media_files_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES public.cameras(id);


--
-- Name: media_files media_files_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: safety_rule_items safety_rule_items_rule_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.safety_rule_items
    ADD CONSTRAINT safety_rule_items_rule_set_id_fkey FOREIGN KEY (rule_set_id) REFERENCES public.safety_rule_sets(id) ON DELETE CASCADE;


--
-- Name: safety_rule_sets safety_rule_sets_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.safety_rule_sets
    ADD CONSTRAINT safety_rule_sets_process_id_fkey FOREIGN KEY (process_id) REFERENCES public.processes(id) ON DELETE CASCADE;


--
-- Name: sop_steps sop_steps_sop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.sop_steps
    ADD CONSTRAINT sop_steps_sop_id_fkey FOREIGN KEY (sop_id) REFERENCES public.sops(id) ON DELETE CASCADE;


--
-- Name: sops sops_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ssg
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_process_id_fkey FOREIGN KEY (process_id) REFERENCES public.processes(id);


--
-- PostgreSQL database dump complete
--

\unrestrict qHr4AALZFeThh6f5qEiC2Chx4n7b30w95OHPNSWfoyNK4Ivl2YmPOWuLJDpzCTO

