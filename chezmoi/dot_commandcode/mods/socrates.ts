// socrates mod — a tool that lets the LLM ask the user structured questions.
// Adapted from the Pi coding agent's ask-tool (pi-ask-tool): the Pi extension used a
// full-screen tabbed TUI; Command Code's ModUi is a line-based Interaction modal, so each
// question becomes one modal (or a small loop for multi-select), and cancelling aborts the
// whole flow.

import type {ModApi} from '@commandcode/harness';

const TOOL_NAME = 'socrates';
const OTHER_OPTION = 'Other (type your own)';
const RECOMMENDED_TAG = ' (Recommended)';

interface AskOption {
	label: string;
}

interface AskQuestion {
	id: string;
	question: string;
	markdownCtx?: string;
	options: AskOption[];
	multi: boolean;
	recommended: number;
}

interface AskSelection {
	selectedOptions: string[];
	customInput?: string;
}

interface QuestionResult extends AskSelection {
	id: string;
	question: string;
	options: string[];
	multi: boolean;
	noneSelected: boolean;
}

class UserCancelled extends Error {}

// ── validation (ported from pi-ask-tool src/index.ts) ────────────────────────────────────

function validateQuestions(questions: AskQuestion[]): string[] {
	const errors: string[] = [];
	for (let i = 0; i < questions.length; i++) {
		const q = questions[i];
		const prefix = `questions[${i}]`;

		if (typeof q.id !== 'string' || q.id.trim().length === 0) {
			errors.push(`${prefix}.id: must be a non-empty string`);
		}
		if (typeof q.question !== 'string' || q.question.trim().length === 0) {
			errors.push(`${prefix}.question: must be a non-empty string`);
		}
		if (q.markdownCtx != null && typeof q.markdownCtx !== 'string') {
			errors.push(`${prefix}.markdownCtx: must be a string`);
		}
		if (!Array.isArray(q.options) || q.options.length === 0) {
			errors.push(`${prefix}.options: must be a non-empty array`);
		} else {
			for (let j = 0; j < q.options.length; j++) {
				const opt = q.options[j];
				if (
					!opt ||
					typeof opt.label !== 'string' ||
					opt.label.trim().length === 0
				) {
					errors.push(`${prefix}.options[${j}].label: must be a non-empty string`);
				}
			}
			if (
				typeof q.recommended !== 'number' ||
				!Number.isFinite(q.recommended)
			) {
				errors.push(`${prefix}.recommended: must be a finite number`);
			} else if (q.recommended < 0 || q.recommended >= q.options.length) {
				errors.push(
					`${prefix}.recommended: must be between 0 and ${q.options.length - 1}`,
				);
			}
		}
		if (typeof q.multi !== 'boolean') {
			errors.push(`${prefix}.multi: must be a boolean`);
		}
	}
	return errors;
}

// ── result building (ported from pi-ask-tool src/ask-logic.ts) ────────────────────────────

function appendRecommendedTag(optionLabels: string[], recommendedIndex: number): string[] {
	return optionLabels.map((label, index) => {
		if (index !== recommendedIndex) return label;
		if (label.endsWith(RECOMMENDED_TAG)) return label;
		return `${label}${RECOMMENDED_TAG}`;
	});
}

function stripRecommendedTag(label: string): string {
	return label.endsWith(RECOMMENDED_TAG)
		? label.slice(0, -RECOMMENDED_TAG.length)
		: label;
}

function formatSelectionText(
	selection: AskSelection,
	multi: boolean,
	emptyText: string,
): string {
	const hasSelectedOptions = selection.selectedOptions.length > 0;
	const hasCustomInput = Boolean(selection.customInput);

	if (hasSelectedOptions && hasCustomInput) {
		const selectedPart = multi
			? `[${selection.selectedOptions.join(', ')}]`
			: selection.selectedOptions[0];
		return `${selectedPart} + Other: "${selection.customInput}"`;
	}
	if (hasCustomInput) return `Other: "${selection.customInput}"`;
	if (hasSelectedOptions) {
		return multi
			? `[${selection.selectedOptions.join(', ')}]`
			: selection.selectedOptions[0];
	}
	return emptyText;
}

// ── session-text sanitization (ported from pi-ask-tool src/index.ts) ──────────────────────

function sanitizeForSessionText(value: string): string {
	return value
		.replace(/[\r\n\t]/g, ' ')
		.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
		.replace(/\s{2,}/g, ' ')
		.trim();
}

function toSessionSafeQuestionResult(result: QuestionResult) {
	const selectedOptions = result.selectedOptions
		.map(sanitizeForSessionText)
		.filter(option => option.length > 0);

	const rawCustomInput = result.customInput;
	const customInput =
		rawCustomInput == null ? undefined : sanitizeForSessionText(rawCustomInput);

	return {
		id: sanitizeForSessionText(result.id) || '(unknown)',
		question: sanitizeForSessionText(result.question) || '(empty question)',
		options: result.options.map(
			option => sanitizeForSessionText(option) || '(empty option)',
		),
		multi: result.multi,
		selectedOptions,
		noneSelected: result.noneSelected,
		customInput:
			customInput && customInput.length > 0 ? customInput : undefined,
	};
}

function formatQuestionResult(result: QuestionResult): string {
	const emptyText = result.noneSelected ? '(none selected)' : '(cancelled)';
	return `${result.id}: ${formatSelectionText(result, result.multi, emptyText)}`;
}

function buildAskSessionContent(results: QuestionResult[]): string {
	const safeResults = results.map(toSessionSafeQuestionResult);
	const summaryLines = safeResults.map(formatQuestionResult).join('\n');
	return `User answers:\n${summaryLines}`;
}

// ── the question flow (modal adaptation of pi-ask-tool's tabbed UI) ───────────────────────

async function askOneQuestion(cmd: ModApi, question: AskQuestion): Promise<AskSelection> {
	const optionLabels = appendRecommendedTag(
		question.options.map(option => option.label),
		question.recommended,
	);

	// Single-select: one pick (or Other), then done.
	if (!question.multi) {
		for (;;) {
			const pick = await cmd.ui.select({
				title: question.question,
				options: [...optionLabels, OTHER_OPTION].map(label => ({label})),
			});
			if (pick === undefined) throw new UserCancelled('user cancelled');
			if (pick === OTHER_OPTION) {
				const text = await cmd.ui.input({
					title: 'Other',
					placeholder: 'type your answer',
				});
				if (text === undefined) throw new UserCancelled('user cancelled');
				const customInput = text.trim();
				if (customInput.length > 0) return {selectedOptions: [], customInput};
				continue; // empty Other → let them pick again
			}
			return {selectedOptions: [stripRecommendedTag(pick)]};
		}
	}

	// Multi-select: keep picking until Done. Nothing picked is valid (noneSelected).
	// Picked options are re-rendered with a "[x] " prefix so the user can see — and
	// re-pick to toggle off — their accumulated selections without growing the title.
	const CHECK = '[x] ';
	const UNCHECK = '[ ] ';
	const selected: string[] = [];
	const customInputs: string[] = [];
	for (;;) {
		const pick = await cmd.ui.select({
			title: question.question,
			options: [
				...optionLabels.map(label => ({
					label: selected.includes(stripRecommendedTag(label))
						? CHECK + label
						: UNCHECK + label,
				})),
				...(customInputs.length > 0
					? [{label: `${CHECK}Other: "${customInputs.join('; ')}"`}]
					: []),
				{label: OTHER_OPTION},
				{label: 'Done'},
			],
		});
		if (pick === undefined) throw new UserCancelled('user cancelled');
		if (pick === 'Done') break;
		if (pick === OTHER_OPTION) {
			const text = await cmd.ui.input({
				title: 'Other',
				placeholder: 'type your answer',
			});
			if (text === undefined) throw new UserCancelled('user cancelled');
			const customInput = text.trim();
			if (customInput.length > 0) {
				customInputs.push(customInput);
				continue; // keep picking after an Other entry
			}
			continue; // empty Other → keep picking
		}
		if (pick.startsWith(CHECK + 'Other: ')) continue; // already-collected Other row — no-op
		const toggled = pick.startsWith(CHECK)
			? pick.slice(CHECK.length)
			: pick.startsWith(UNCHECK)
				? pick.slice(UNCHECK.length)
				: pick;
		const label = stripRecommendedTag(toggled);
		const index = selected.indexOf(label);
		if (index >= 0) selected.splice(index, 1); // toggle off
		else selected.push(label);
	}
	return {
		selectedOptions: selected,
		customInput: customInputs.length > 0 ? customInputs.join('; ') : undefined,
	};
}

// ── tool registration ─────────────────────────────────────────────────────────────────────

export default function (cmd: ModApi): void {
	cmd.addTool({
		schema: {
			name: TOOL_NAME,
			description:
				'Ask the user one or more structured questions. Use this to gather user input, decisions, or preferences before acting — ALWAYS ask instead of guessing.',
			input_schema: {
				type: 'object',
				properties: {
					questions: {
						type: 'array',
						minItems: 1,
						description: 'Questions to ask the user, in order.',
						items: {
							type: 'object',
							properties: {
								id: {
									type: 'string',
									description: 'Unique key for this question, used in the answer summary.',
								},
								question: {
									type: 'string',
									description: 'The question to ask the user.',
								},
								markdownCtx: {
									type: 'string',
									description: 'Optional context alongside the question.',
								},
								options: {
									type: 'array',
									minItems: 1,
									description: 'Choices for the user. Do NOT include an "Other" option — it is added automatically.',
									items: {
										type: 'object',
										properties: {
											label: {type: 'string', description: "The choice's text the user sees."},
										},
										required: ['label'],
									},
								},
								multi: {
									type: 'boolean',
									description: 'Whether the user may pick several options.',
								},
								recommended: {
									type: 'integer',
									description: 'Your recommended option, 0-indexed into options.',
								},
							},
							required: ['id', 'question', 'options', 'multi', 'recommended'],
						},
					},
				},
				required: ['questions'],
			},
		},
		readOnly: true,
		run: async ({input}) => {
			const questions = Array.isArray(input?.questions) ? input.questions : [];

			// No interactive UI (headless/print mode): fail fast rather than produce
			// garbage from the deterministic undefined dialog defaults.
			if (!cmd.ui.capabilities.status) {
				return {ok: false, error: `${TOOL_NAME} requires an interactive TUI`};
			}
			if (questions.length === 0) {
				return {ok: false, error: 'questions must not be empty'};
			}

			const validationErrors = validateQuestions(questions);
			if (validationErrors.length > 0) {
				return {
					ok: false,
					error: `Validation errors:\n${validationErrors
						.map(e => `  - ${e}`)
						.join('\n')}`,
				};
			}

			cmd.ui.notify(`⏳ ${TOOL_NAME}: waiting for your answers…`);
			cmd.events.emit('herdr:blocked', {active: true, label: TOOL_NAME});

			const results: QuestionResult[] = [];
			try {
				for (const question of questions) {
					const selection = await askOneQuestion(cmd, question);
					results.push({
						id: question.id,
						question: question.question,
						options: question.options.map(option => option.label),
						multi: question.multi,
						selectedOptions: selection.selectedOptions,
						customInput: selection.customInput,
						noneSelected:
							question.multi &&
							selection.selectedOptions.length === 0 &&
							selection.customInput == null,
					});
				}
			} catch (error) {
				if (error instanceof UserCancelled) {
					return {
						ok: false,
						error: `${TOOL_NAME}: user cancelled the question flow`,
					};
				}
				throw error;
			} finally {
				// Always clear the blocked flag, even on cancellation/error — a
				// stale "blocked" cell is worse than a missed one.
				cmd.events.emit('herdr:blocked', {active: false, label: TOOL_NAME});
			}

			cmd.ui.notify(`✓ ${TOOL_NAME}: answers received`);
			return {
				ok: true,
				content: [{type: 'text', text: buildAskSessionContent(results)}],
			};
		},
	});
}
