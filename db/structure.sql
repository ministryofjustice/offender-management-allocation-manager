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

--
-- Name: offender_email_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.offender_email_type AS ENUM (
    'upcoming_handover_window',
    'handover_date',
    'com_allocation_overdue'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: allocation_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.allocation_history (
    id bigint NOT NULL,
    nomis_offender_id character varying,
    prison character varying,
    allocated_at_tier character varying,
    override_reasons character varying,
    override_detail character varying,
    message character varying,
    suitability_detail character varying,
    primary_pom_name character varying,
    secondary_pom_name character varying,
    created_by_name character varying,
    primary_pom_nomis_id integer,
    secondary_pom_nomis_id integer,
    event integer,
    event_trigger integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    primary_pom_allocated_at timestamp without time zone,
    recommended_pom_type character varying
);


--
-- Name: allocation_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.allocation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allocation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.allocation_history_id_seq OWNED BY public.allocation_history.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nomis_offender_id text,
    tags text[] NOT NULL,
    published_at timestamp(6) without time zone NOT NULL,
    system_event boolean,
    username text,
    user_human_name text,
    data jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT system_event_cannot_have_user_details CHECK ((((system_event = true) AND (username IS NULL) AND (user_human_name IS NULL)) OR (system_event = false)))
);


--
-- Name: calculated_early_allocation_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calculated_early_allocation_statuses (
    nomis_offender_id character varying NOT NULL,
    eligible boolean NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: calculated_handover_dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calculated_handover_dates (
    id bigint NOT NULL,
    start_date date,
    handover_date date,
    reason character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    nomis_offender_id character varying NOT NULL,
    responsibility character varying
);


--
-- Name: calculated_handover_dates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calculated_handover_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calculated_handover_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calculated_handover_dates_id_seq OWNED BY public.calculated_handover_dates.id;


--
-- Name: case_information; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.case_information (
    id bigint NOT NULL,
    tier character varying,
    nomis_offender_id character varying,
    crn character varying,
    mappa_level integer,
    manual_entry boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    probation_service character varying,
    com_name character varying,
    team_name character varying,
    local_delivery_unit_id bigint,
    ldu_code character varying,
    com_email character varying,
    active_vlo boolean DEFAULT false,
    enhanced_handover boolean NOT NULL
);


--
-- Name: case_information_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.case_information_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_information_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.case_information_id_seq OWNED BY public.case_information.id;


--
-- Name: contact_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contact_submissions (
    id bigint NOT NULL,
    message text NOT NULL,
    email_address character varying,
    referrer character varying,
    user_agent character varying,
    prison character varying,
    name character varying,
    job_type character varying
);


--
-- Name: contact_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contact_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contact_submissions_id_seq OWNED BY public.contact_submissions.id;


--
-- Name: delius_import_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delius_import_errors (
    id bigint NOT NULL,
    nomis_offender_id character varying,
    error_type integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delius_import_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delius_import_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delius_import_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delius_import_errors_id_seq OWNED BY public.delius_import_errors.id;


--
-- Name: early_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.early_allocations (
    id bigint NOT NULL,
    nomis_offender_id character varying NOT NULL,
    oasys_risk_assessment_date date NOT NULL,
    convicted_under_terrorisom_act_2000 boolean NOT NULL,
    high_profile boolean NOT NULL,
    serious_crime_prevention_order boolean NOT NULL,
    mappa_level_3 boolean NOT NULL,
    cppc_case boolean NOT NULL,
    high_risk_of_serious_harm boolean,
    mappa_level_2 boolean,
    pathfinder_process boolean,
    other_reason boolean,
    extremism_separation boolean,
    due_for_release_in_less_than_24months boolean,
    approved boolean,
    reason character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    community_decision boolean,
    prison character varying,
    created_by_firstname character varying,
    created_by_lastname character varying,
    updated_by_firstname character varying,
    updated_by_lastname character varying,
    created_within_referral_window boolean DEFAULT false NOT NULL,
    outcome character varying NOT NULL
);


--
-- Name: early_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.early_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: early_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.early_allocations_id_seq OWNED BY public.early_allocations.id;


--
-- Name: email_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_histories (
    id bigint NOT NULL,
    prison character varying NOT NULL,
    nomis_offender_id character varying NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    event character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: email_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_histories_id_seq OWNED BY public.email_histories.id;


--
-- Name: flipflop_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipflop_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flipflop_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipflop_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipflop_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipflop_features_id_seq OWNED BY public.flipflop_features.id;


--
-- Name: handover_progress_checklists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.handover_progress_checklists (
    id bigint NOT NULL,
    nomis_offender_id character varying NOT NULL,
    reviewed_oasys boolean DEFAULT false NOT NULL,
    contacted_com boolean DEFAULT false NOT NULL,
    attended_handover_meeting boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    sent_handover_report boolean DEFAULT false NOT NULL
);


--
-- Name: handover_progress_checklists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.handover_progress_checklists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: handover_progress_checklists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.handover_progress_checklists_id_seq OWNED BY public.handover_progress_checklists.id;


--
-- Name: local_delivery_units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.local_delivery_units (
    id bigint NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    email_address character varying NOT NULL,
    country character varying NOT NULL,
    enabled boolean NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: local_delivery_units_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.local_delivery_units_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: local_delivery_units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.local_delivery_units_id_seq OWNED BY public.local_delivery_units.id;


--
-- Name: offender_email_opt_outs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offender_email_opt_outs (
    id bigint NOT NULL,
    staff_member_id character varying NOT NULL,
    offender_email_type public.offender_email_type NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: offender_email_opt_outs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offender_email_opt_outs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offender_email_opt_outs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offender_email_opt_outs_id_seq OWNED BY public.offender_email_opt_outs.id;


--
-- Name: offender_email_sent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offender_email_sent (
    id bigint NOT NULL,
    nomis_offender_id character varying NOT NULL,
    staff_member_id character varying NOT NULL,
    offender_email_type public.offender_email_type NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: offender_email_sent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offender_email_sent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offender_email_sent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offender_email_sent_id_seq OWNED BY public.offender_email_sent.id;


--
-- Name: offender_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offender_events (
    id bigint NOT NULL,
    nomis_offender_id character varying NOT NULL,
    type character varying NOT NULL,
    happened_at timestamp without time zone NOT NULL,
    triggered_by character varying NOT NULL,
    triggered_by_nomis_username character varying,
    metadata jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: offender_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offender_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offender_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offender_events_id_seq OWNED BY public.offender_events.id;


--
-- Name: offenders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offenders (
    nomis_offender_id character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: parole_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parole_records (
    nomis_offender_id character varying NOT NULL,
    parole_review_date date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pom_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pom_details (
    id bigint NOT NULL,
    nomis_staff_id integer,
    working_pattern double precision,
    status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    prison_code character varying
);


--
-- Name: pom_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pom_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pom_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pom_details_id_seq OWNED BY public.pom_details.id;


--
-- Name: prisons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prisons (
    prison_type character varying NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: responsibilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.responsibilities (
    id bigint NOT NULL,
    nomis_offender_id character varying NOT NULL,
    reason integer NOT NULL,
    reason_text character varying,
    value character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: responsibilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.responsibilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: responsibilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.responsibilities_id_seq OWNED BY public.responsibilities.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    item_type character varying NOT NULL,
    item_id bigint NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp without time zone,
    object_changes text,
    nomis_offender_id character varying,
    user_first_name character varying,
    user_last_name character varying,
    prison character varying,
    offender_attributes_to_archive jsonb
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: victim_liaison_officers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.victim_liaison_officers (
    id bigint NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    email character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    nomis_offender_id character varying(7) NOT NULL
);


--
-- Name: victim_liaison_officers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.victim_liaison_officers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: victim_liaison_officers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.victim_liaison_officers_id_seq OWNED BY public.victim_liaison_officers.id;


--
-- Name: allocation_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allocation_history ALTER COLUMN id SET DEFAULT nextval('public.allocation_history_id_seq'::regclass);


--
-- Name: calculated_handover_dates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculated_handover_dates ALTER COLUMN id SET DEFAULT nextval('public.calculated_handover_dates_id_seq'::regclass);


--
-- Name: case_information id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_information ALTER COLUMN id SET DEFAULT nextval('public.case_information_id_seq'::regclass);


--
-- Name: contact_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_submissions ALTER COLUMN id SET DEFAULT nextval('public.contact_submissions_id_seq'::regclass);


--
-- Name: delius_import_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delius_import_errors ALTER COLUMN id SET DEFAULT nextval('public.delius_import_errors_id_seq'::regclass);


--
-- Name: early_allocations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.early_allocations ALTER COLUMN id SET DEFAULT nextval('public.early_allocations_id_seq'::regclass);


--
-- Name: email_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_histories ALTER COLUMN id SET DEFAULT nextval('public.email_histories_id_seq'::regclass);


--
-- Name: flipflop_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipflop_features ALTER COLUMN id SET DEFAULT nextval('public.flipflop_features_id_seq'::regclass);


--
-- Name: handover_progress_checklists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handover_progress_checklists ALTER COLUMN id SET DEFAULT nextval('public.handover_progress_checklists_id_seq'::regclass);


--
-- Name: local_delivery_units id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.local_delivery_units ALTER COLUMN id SET DEFAULT nextval('public.local_delivery_units_id_seq'::regclass);


--
-- Name: offender_email_opt_outs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offender_email_opt_outs ALTER COLUMN id SET DEFAULT nextval('public.offender_email_opt_outs_id_seq'::regclass);


--
-- Name: offender_email_sent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offender_email_sent ALTER COLUMN id SET DEFAULT nextval('public.offender_email_sent_id_seq'::regclass);


--
-- Name: offender_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offender_events ALTER COLUMN id SET DEFAULT nextval('public.offender_events_id_seq'::regclass);


--
-- Name: pom_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pom_details ALTER COLUMN id SET DEFAULT nextval('public.pom_details_id_seq'::regclass);


--
-- Name: responsibilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsibilities ALTER COLUMN id SET DEFAULT nextval('public.responsibilities_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: victim_liaison_officers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.victim_liaison_officers ALTER COLUMN id SET DEFAULT nextval('public.victim_liaison_officers_id_seq'::regclass);


--
-- Name: allocation_history allocation_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allocation_history
    ADD CONSTRAINT allocation_history_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: calculated_early_allocation_statuses calculated_early_allocation_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculated_early_allocation_statuses
    ADD CONSTRAINT calculated_early_allocation_statuses_pkey PRIMARY KEY (nomis_offender_id);


--
-- Name: calculated_handover_dates calculated_handover_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculated_handover_dates
    ADD CONSTRAINT calculated_handover_dates_pkey PRIMARY KEY (id);


--
-- Name: case_information case_information_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_information
    ADD CONSTRAINT case_information_pkey PRIMARY KEY (id);


--
-- Name: contact_submissions contact_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_submissions
    ADD CONSTRAINT contact_submissions_pkey PRIMARY KEY (id);


--
-- Name: delius_import_errors delius_import_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delius_import_errors
    ADD CONSTRAINT delius_import_errors_pkey PRIMARY KEY (id);


--
-- Name: early_allocations early_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.early_allocations
    ADD CONSTRAINT early_allocations_pkey PRIMARY KEY (id);


--
-- Name: email_histories email_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_histories
    ADD CONSTRAINT email_histories_pkey PRIMARY KEY (id);


--
-- Name: flipflop_features flipflop_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipflop_features
    ADD CONSTRAINT flipflop_features_pkey PRIMARY KEY (id);


--
-- Name: handover_progress_checklists handover_progress_checklists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handover_progress_checklists
    ADD CONSTRAINT handover_progress_checklists_pkey PRIMARY KEY (id);


--
-- Name: local_delivery_units local_delivery_units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.local_delivery_units
    ADD CONSTRAINT local_delivery_units_pkey PRIMARY KEY (id);


--
-- Name: offender_email_opt_outs offender_email_opt_outs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offender_email_opt_outs
    ADD CONSTRAINT offender_email_opt_outs_pkey PRIMARY KEY (id);


--
-- Name: offender_email_sent offender_email_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offender_email_sent
    ADD CONSTRAINT offender_email_sent_pkey PRIMARY KEY (id);


--
-- Name: offender_events offender_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offender_events
    ADD CONSTRAINT offender_events_pkey PRIMARY KEY (id);


--
-- Name: offenders offenders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offenders
    ADD CONSTRAINT offenders_pkey PRIMARY KEY (nomis_offender_id);


--
-- Name: parole_records parole_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parole_records
    ADD CONSTRAINT parole_records_pkey PRIMARY KEY (nomis_offender_id);


--
-- Name: pom_details pom_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pom_details
    ADD CONSTRAINT pom_details_pkey PRIMARY KEY (id);


--
-- Name: prisons prisons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prisons
    ADD CONSTRAINT prisons_pkey PRIMARY KEY (code);


--
-- Name: responsibilities responsibilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responsibilities
    ADD CONSTRAINT responsibilities_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: victim_liaison_officers victim_liaison_officers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.victim_liaison_officers
    ADD CONSTRAINT victim_liaison_officers_pkey PRIMARY KEY (id);


--
-- Name: index_allocation_history_on_nomis_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_allocation_history_on_nomis_offender_id ON public.allocation_history USING btree (nomis_offender_id);


--
-- Name: index_allocation_history_on_primary_pom_nomis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allocation_history_on_primary_pom_nomis_id ON public.allocation_history USING btree (primary_pom_nomis_id);


--
-- Name: index_allocation_history_on_prison; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allocation_history_on_prison ON public.allocation_history USING btree (prison);


--
-- Name: index_allocation_versions_secondary_pom_nomis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allocation_versions_secondary_pom_nomis_id ON public.allocation_history USING btree (secondary_pom_nomis_id);


--
-- Name: index_calculated_handover_dates_on_nomis_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_calculated_handover_dates_on_nomis_offender_id ON public.calculated_handover_dates USING btree (nomis_offender_id);


--
-- Name: index_case_information_on_local_delivery_unit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_case_information_on_local_delivery_unit_id ON public.case_information USING btree (local_delivery_unit_id);


--
-- Name: index_case_information_on_nomis_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_case_information_on_nomis_offender_id ON public.case_information USING btree (nomis_offender_id);


--
-- Name: index_handover_progress_checklists_on_nomis_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_handover_progress_checklists_on_nomis_offender_id ON public.handover_progress_checklists USING btree (nomis_offender_id);


--
-- Name: index_local_delivery_units_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_local_delivery_units_on_code ON public.local_delivery_units USING btree (code);


--
-- Name: index_offender_email_opt_out_unique_composite_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_offender_email_opt_out_unique_composite_key ON public.offender_email_opt_outs USING btree (staff_member_id, offender_email_type);


--
-- Name: index_offender_email_sent_on_nomis_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offender_email_sent_on_nomis_offender_id ON public.offender_email_sent USING btree (nomis_offender_id);


--
-- Name: index_offender_email_sent_unique_composite_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_offender_email_sent_unique_composite_key ON public.offender_email_sent USING btree (nomis_offender_id, staff_member_id, offender_email_type);


--
-- Name: index_offender_events_on_nomis_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offender_events_on_nomis_offender_id ON public.offender_events USING btree (nomis_offender_id);


--
-- Name: index_offender_events_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offender_events_on_type ON public.offender_events USING btree (type);


--
-- Name: index_pom_details_on_nomis_staff_id_and_prison_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pom_details_on_nomis_staff_id_and_prison_code ON public.pom_details USING btree (nomis_staff_id, prison_code);


--
-- Name: index_prisons_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_prisons_on_name ON public.prisons USING btree (name);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_nomis_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_nomis_offender_id ON public.versions USING btree (nomis_offender_id);


--
-- Name: index_victim_liaison_officers_on_nomis_offender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_victim_liaison_officers_on_nomis_offender_id ON public.victim_liaison_officers USING btree (nomis_offender_id);


--
-- Name: handover_progress_checklists fk_rails_0f7d3e1f9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handover_progress_checklists
    ADD CONSTRAINT fk_rails_0f7d3e1f9a FOREIGN KEY (nomis_offender_id) REFERENCES public.offenders(nomis_offender_id);


--
-- Name: offender_email_sent fk_rails_5f6304c3c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offender_email_sent
    ADD CONSTRAINT fk_rails_5f6304c3c6 FOREIGN KEY (nomis_offender_id) REFERENCES public.offenders(nomis_offender_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20190128103429'),
('20190128103927'),
('20190129090414'),
('20190129091428'),
('20190201073917'),
('20190201145056'),
('20190201145633'),
('20190201152308'),
('20190201153452'),
('20190204122216'),
('20190204123001'),
('20190205103929'),
('20190205104045'),
('20190205104220'),
('20190207143221'),
('20190210105233'),
('20190210132134'),
('20190212160351'),
('20190214094443'),
('20190214113519'),
('20190221082427'),
('20190226132354'),
('20190301092256'),
('20190320130118'),
('20190322094954'),
('20190423095925'),
('20190426085505'),
('20190503130223'),
('20190503130224'),
('20190503130410'),
('20190507110142'),
('20190507144554'),
('20190516112018'),
('20190624112547'),
('20190624130035'),
('20190626062807'),
('20190626063100'),
('20190626093827'),
('20190705150401'),
('20190710065151'),
('20190715082230'),
('20190717064658'),
('20190723102205'),
('20190726135613'),
('20190729070713'),
('20190805120051'),
('20190809062337'),
('20190809140516'),
('20190812124731'),
('20190813080602'),
('20190909115431'),
('20190913113448'),
('20190918084437'),
('20190919074927'),
('20190923092754'),
('20190924133346'),
('20191003142825'),
('20191010090002'),
('20191022074139'),
('20191120095310'),
('20191126081703'),
('20191204142527'),
('20191212110913'),
('20200304155347'),
('20200528112343'),
('20200528165050'),
('20200803135050'),
('20201014082050'),
('20201023133523'),
('20201028105256'),
('20201028113448'),
('20201028160716'),
('20201111134425'),
('20201116101450'),
('20201118175237'),
('20201119092144'),
('20201126123414'),
('20201127172113'),
('20201207090113'),
('20201207113504'),
('20201208130833'),
('20201214130556'),
('20201215133824'),
('20210331115125'),
('20210419085828'),
('20210419101956'),
('20210419131040'),
('20210429144703'),
('20210512103739'),
('20210521122123'),
('20210525134556'),
('20210525140412'),
('20210603122414'),
('20210604081125'),
('20210604153151'),
('20210618083355'),
('20210708094108'),
('20210709083336'),
('20210709085128'),
('20210716080850'),
('20210719125108'),
('20220816170141'),
('20221104000001'),
('20221123000001'),
('20221216000001'),
('20230213000001'),
('20230213000002'),
('20230213000003'),
('20230412150435'),
('20230602102101'),
('20230602163929'),
('20230613125426'),
('20230712000001');


